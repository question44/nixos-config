"""Loopback-only dashboard actions; Caddy supplies the private-network boundary."""

import json
import os
import socket
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


HOSTS = {"moria", "erebor", "localhost", "127.0.0.1", "moria.local", "erebor.local",
         "moria.jzon.pl", "erebor.jzon.pl"}
ACTIONS = {"display-on", "display-off", "ambilight-on", "ambilight-off", "sleep", "power-off"}
AMBILIGHT_LOCK = threading.Lock()


def wled_state(state):
    url = os.environ["DASHBOARD_WLED_URL"].rstrip("/") + "/json/state"
    request = Request(url, data=json.dumps(state).encode(),
                      headers={"Content-Type": "application/json"})
    with urlopen(request, timeout=5) as response:
        result = json.load(response)
    if not result.get("success"):
        raise RuntimeError("WLED rejected the power command")


def hyperhdr_leds(enabled):
    request = {"command": "componentstate", "componentstate": {
        "component": "LEDDEVICE", "state": enabled}, "tan": 1}
    with socket.create_connection(("127.0.0.1", 19444), timeout=5) as sock:
        sock.sendall((json.dumps(request) + "\n").encode())
        with sock.makefile("rb") as stream:
            response = json.loads(stream.readline(65536))
    if not response.get("success"):
        raise RuntimeError(response.get("error", "HyperHDR rejected the request"))


def run(*args, env=None):
    return subprocess.run(args, env=env, check=True, capture_output=True, text=True, timeout=12).stdout


def session_environment():
    env = os.environ.copy()
    # Refresh for each request: the service can outlive compositor logins.
    for line in run("systemctl", "--user", "show-environment").splitlines():
        key, sep, value = line.partition("=")
        if sep and key in {"WAYLAND_DISPLAY", "XDG_CURRENT_DESKTOP", "NIRI_SOCKET",
                           "UMBRIEL_SOCKET", "MANGO_INSTANCE_SIGNATURE"}:
            env[key] = value
    return env


def action(name):
    if name.startswith("display-"):
        state = name.removeprefix("display-")
        env = session_environment()
        desktop = env.get("XDG_CURRENT_DESKTOP", "").lower()
        if desktop == "mango":
            monitors = json.loads(run("mmsg", "get", "all-monitors", env=env))["monitors"]
            outputs = [m["name"] for m in monitors if m["name"] not in {"ambilight", "sunshine"}]
            if not outputs:
                raise RuntimeError("No physical display found")
            for output in outputs:
                run("wlopm", "--" + state, output, env=env)
        elif desktop == "umbriel":
            outputs = json.loads(run("umbriel", "outputs", "--json", env=env))
            for output in outputs:
                if output["name"] not in {"ambilight", "sunshine"}:
                    run("umbriel", "msg", "dpms-" + state + ":" + output["name"], env=env)
        elif desktop == "niri":
            run("niri", "msg", "action", "power-" + state + "-monitors", env=env)
        else:
            raise RuntimeError("No supported desktop session is running")
    elif name.startswith("ambilight-"):
        # WLED can retain realtime output despite acknowledging power off.
        # Override it until explicitly enabled, preserving PipeWire capture.
        with AMBILIGHT_LOCK:
            if name == "ambilight-on":
                wled_state({"lor": 0, "on": True})
                hyperhdr_leds(True)
            else:
                hyperhdr_leds(False)
                wled_state({"on": False, "live": False, "lor": 2})
    elif name in {"sleep", "power-off"}:
        # login1 applies the existing wheel policy and respects inhibitors.
        method = "Suspend" if name == "sleep" else "PowerOff"
        run("busctl", "--system", "--allow-interactive-authorization=no", "call",
            "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", method, "b", "false")
    else:
        raise ValueError("Unknown action")


class Handler(BaseHTTPRequestHandler):
    def reply(self, status, **payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        origin = urlsplit(self.headers.get("Origin", ""))
        host = self.headers.get("Host", "")
        try:
            import ipaddress
            address = ipaddress.ip_address(origin.hostname or "")
            trusted = address.is_private and not address.is_unspecified and not address.is_multicast
            trusted |= address in ipaddress.ip_network("100.64.0.0/10") if address.version == 4 else False
        except ValueError:
            trusted = origin.hostname in HOSTS
        if (not trusted or origin.scheme not in {"http", "https"} or origin.netloc != host
                or origin.path or origin.query or origin.fragment
                or self.headers.get("X-Erebor-Control") != "1"
                or self.headers.get("Content-Type") != "application/json"):
            self.reply(403, error="Same-origin dashboard requests only")
            return
        if self.path != "/api/control":
            self.reply(404, error="Unknown endpoint")
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 256:
                raise ValueError("Invalid request size")
            name = json.loads(self.rfile.read(length)).get("action")
            if name not in ACTIONS:
                raise ValueError("Unknown action")
        except (ValueError, TypeError, AttributeError):
            self.reply(400, error="Invalid action")
            return
        try:
            action(name)
        except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
            print(f"{name} failed: {exc}", flush=True)
            self.reply(503, error="Action failed. Check the desktop session and control service log.")
            return
        self.reply(200, message="Command sent")


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 18090), Handler).serve_forever()
