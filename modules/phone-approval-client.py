"""Ask the phone-approval service for an approval and send its link to the phone.

  phone-approval-client approve   (from pam_exec: PAM_USER, PAM_TYPE)
  phone-approval-client enroll USER

Runs as root. The link goes to the phone through KDE Connect in the user's
session (`kdeconnect-cli --share`). Exits 0 only when the service reports
that the phone's passkey approved this request.
"""

import json
import os
import pwd
import re
import socket
import subprocess
import sys
import time

SOCKET = "/run/phone-approval/pam.sock"
DEVICE = os.environ["PHONE_APPROVAL_DEVICE"]
TIMEOUT = float(os.environ.get("PHONE_APPROVAL_TIMEOUT", "30"))
REASON_DIR = "/run/auth-reason"
USER_RE = re.compile(r"^[a-z_][a-z0-9_-]*$")


def log(msg):
    print(f"phone-approval: {msg}", file=sys.stderr, flush=True)


def kdeconnect(user, *args):
    """Run kdeconnect-cli as `user` against their session's kdeconnectd."""
    pw = pwd.getpwnam(user)
    runtime = f"/run/user/{pw.pw_uid}"
    if not os.path.exists(f"{runtime}/bus"):
        return None
    env = {
        "PATH": os.environ.get("PATH", ""),
        "HOME": pw.pw_dir,
        "USER": user,
        "XDG_RUNTIME_DIR": runtime,
        "DBUS_SESSION_BUS_ADDRESS": f"unix:path={runtime}/bus",
        "QT_QPA_PLATFORM": "offscreen",
    }
    cmd = [
        "setpriv",
        f"--reuid={pw.pw_uid}",
        f"--regid={pw.pw_gid}",
        "--init-groups",
        "kdeconnect-cli",
        *args,
    ]
    try:
        r = subprocess.run(
            cmd, env=env, capture_output=True, text=True, timeout=5, stdin=subprocess.DEVNULL
        )
    except subprocess.TimeoutExpired:
        return None
    return r


def reachable(user):
    r = kdeconnect(user, "--list-available", "--id-only")
    return r is not None and DEVICE in r.stdout.split()


def reason(user):
    try:
        with open(f"{REASON_DIR}/{user}") as f:
            stamp, what = f.readline().rstrip("\n").split("\t", 1)
        if time.time() - int(stamp) < 30:
            return what
    except (OSError, ValueError):
        pass
    return ""


def request(user, msg, wait):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(SOCKET)
    s.sendall((json.dumps({**msg, "user": user}) + "\n").encode())
    f = s.makefile("r")
    first = json.loads(f.readline() or "{}")
    if "url" not in first:
        log(f"service: {first.get('error', 'no answer')}")
        return None
    r = kdeconnect(user, "--device", DEVICE, "--share", first["url"])
    if r is None or r.returncode != 0:
        log(f"could not send the link to the phone: {r.stderr.strip() if r else 'no session'}")
        return None
    if msg["op"] == "enroll":
        print(f"Link sent to the phone. It is also here:\n  {first['url']}", flush=True)
    s.settimeout(wait + 5)
    try:
        return json.loads(f.readline() or "{}").get("result")
    except (socket.timeout, ValueError):
        return "timeout"


def main():
    if sys.argv[1:2] == ["enroll"]:
        user = sys.argv[2]
        if not USER_RE.match(user) or not reachable(user):
            sys.exit(f"The phone ({DEVICE}) is not reachable in {user}'s KDE Connect.")
        result = request(user, {"op": "enroll"}, 600)
        print(f"Result: {result}")
        sys.exit(0 if result == "enrolled" else 1)

    if os.environ.get("PAM_TYPE") != "auth":
        sys.exit(1)
    user = os.environ.get("PAM_USER", "")
    if not USER_RE.match(user):
        sys.exit(1)
    # Skip at once when the phone isn't connected, so the next method
    # (YubiKey, password) isn't delayed.
    if not reachable(user):
        sys.exit(1)
    result = request(user, {"op": "approve", "reason": reason(user), "timeout": TIMEOUT}, TIMEOUT)
    log(f"{user}: {result}")
    sys.exit(0 if result == "approved" else 1)


if __name__ == "__main__":
    main()
