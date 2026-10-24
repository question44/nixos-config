"""Loopback-only dashboard actions; Caddy supplies the private-network boundary."""

import ipaddress
import json
import os
import socket
import subprocess
import threading
from typing import Annotated, Literal, get_args
from urllib.parse import urlsplit
from urllib.request import Request as URLRequest, urlopen

from fastapi import FastAPI, Header, Request
from fastapi.exceptions import RequestValidationError
from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict
from starlette.datastructures import Headers, MutableHeaders
from starlette.exceptions import HTTPException
from starlette.types import ASGIApp, Message, Receive, Scope, Send
import uvicorn


HOSTS = {"moria", "erebor", "localhost", "127.0.0.1", "moria.local", "erebor.local",
         "moria.jzon.pl", "erebor.jzon.pl"}
ActionName = Literal["display-on", "display-off", "ambilight-on", "ambilight-off", "sleep", "power-off", "reboot-windows"]
ACTIONS = set(get_args(ActionName))
AMBILIGHT_LOCK = threading.Lock()


def wled_state(state):
    url = os.environ["DASHBOARD_WLED_URL"].rstrip("/") + "/json/state"
    request = URLRequest(url, data=json.dumps(state).encode(),
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


def run(*args, env=None, timeout=12):
    return subprocess.run(args, env=env, check=True, capture_output=True, text=True, timeout=timeout).stdout


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
    elif name == "reboot-windows":
        run("systemctl", "--system", "--no-ask-password", "start",
            "dashboard-reboot-windows.service", timeout=65)
    elif name in {"sleep", "power-off"}:
        # login1 applies the existing wheel policy and respects inhibitors.
        method = "Suspend" if name == "sleep" else "PowerOff"
        run("busctl", "--system", "--allow-interactive-authorization=no", "call",
            "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", method, "b", "false")
    else:
        raise ValueError("Unknown action")


class ControlCommand(BaseModel):
    model_config = ConfigDict(extra="forbid")
    action: ActionName


class ControlResult(BaseModel):
    message: str


class ControlError(BaseModel):
    error: str


def same_origin(headers: Headers) -> bool:
    try:
        origin = urlsplit(headers.get("origin", ""))
        hostname = origin.hostname or ""
        try:
            address = ipaddress.ip_address(hostname)
            trusted = address.is_private and not address.is_unspecified and not address.is_multicast
            if address.version == 4:
                trusted |= address in ipaddress.ip_network("100.64.0.0/10")
        except ValueError:
            trusted = hostname in HOSTS
        return bool(trusted and origin.scheme in {"http", "https"}
                    and origin.netloc == headers.get("host", "")
                    and not (origin.path or origin.query or origin.fragment)
                    and headers.get("x-erebor-control") == "1"
                    and headers.get("content-type") == "application/json"
                    and all(len(headers.getlist(name)) == 1 for name in
                            ["host", "origin", "x-erebor-control", "content-type"]))
    except ValueError:
        return False


class DashboardBoundary:
    """Apply the existing browser boundary before FastAPI parses any body."""

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def no_store(message: Message):
            if message["type"] == "http.response.start":
                MutableHeaders(scope=message)["Cache-Control"] = "no-store"
            await send(message)

        if scope["method"] == "POST":
            headers = Headers(scope=scope)
            if not same_origin(headers):
                await JSONResponse({"error": "Same-origin dashboard requests only"}, 403)(scope, receive, no_store)
                return
            if scope["path"] != "/api/control" or scope.get("query_string"):
                await JSONResponse({"error": "Unknown endpoint"}, 404)(scope, receive, no_store)
                return
            try:
                length = int(headers.get("content-length", "0"))
                if not 0 < length <= 256 or len(headers.getlist("content-length")) != 1:
                    raise ValueError("Invalid request size")
            except ValueError:
                await JSONResponse({"error": "Invalid action"}, 400)(scope, receive, no_store)
                return
            received = 0
            original_receive = receive

            async def bounded_receive():
                nonlocal received
                message = await original_receive()
                if message["type"] == "http.request":
                    received += len(message.get("body", b""))
                    if received > 256 or (not message.get("more_body", False) and received != length):
                        raise HTTPException(400, "Invalid action")
                return message

            receive = bounded_receive
        await self.app(scope, receive, no_store)


app = FastAPI(title="erebor control API", version="1.0.0", redirect_slashes=False,
              docs_url="/api/control/docs", redoc_url=None,
              openapi_url="/api/control/openapi.json")
app.add_middleware(DashboardBoundary)


@app.exception_handler(RequestValidationError)
async def invalid_command(request: Request, exc: RequestValidationError):
    return JSONResponse({"error": "Invalid action"}, 400)


@app.exception_handler(HTTPException)
async def http_error(request: Request, exc: HTTPException):
    return JSONResponse({"error": "Invalid action" if exc.status_code == 400 else str(exc.detail)},
                        exc.status_code, headers=exc.headers)


@app.post("/api/control", response_model=ControlResult,
          responses={code: {"model": ControlError} for code in [400, 403, 503]})
def execute_control(command: ControlCommand,
                    x_erebor_control: Annotated[Literal["1"], Header(alias="X-Erebor-Control")]):
    # FastAPI runs this synchronous handler in its thread pool.
    try:
        action(command.action)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        print(f"{command.action} failed: {exc}", flush=True)
        return JSONResponse({"error": "Action failed. Check the desktop session and control service log."}, 503)
    return ControlResult(message="Command sent")


def control_openapi():
    if app.openapi_schema is None:
        app.openapi_schema = get_openapi(title=app.title, version=app.version, routes=app.routes)
        # Validation keeps the existing 400 response contract rather than 422.
        app.openapi_schema["paths"]["/api/control"]["post"]["responses"].pop("422", None)
    return app.openapi_schema


app.openapi = control_openapi

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=18090, proxy_headers=False, server_header=False)
