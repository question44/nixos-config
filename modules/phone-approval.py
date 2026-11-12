"""Phone approval for sudo: a passkey on the phone signs each request.

Runs as a system service. The PAM helper (root) asks for an approval over a
root-only Unix socket and gets back a one-time link, which it sends to the
phone with KDE Connect. The phone opens the link (served through Caddy) and
approves with its passkey; this service checks the WebAuthn assertion against
the credential stored in its state directory and answers the helper.

Socket protocol: one JSON line in, JSON lines out.
  {"op": "approve", "user": U, "reason": R, "timeout": S}
      -> {"url": ...} then {"result": "approved" | "denied" | "timeout"}
      -> {"error": "not-enrolled"} when U has no passkey
  {"op": "enroll", "user": U}
      -> {"url": ...} then {"result": "enrolled" | "timeout" | "failed"}
"""

import html
import json
import os
import re
import secrets
import socket
import socketserver
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from webauthn import (
    generate_authentication_options,
    generate_registration_options,
    options_to_json,
    verify_authentication_response,
    verify_registration_response,
)
from webauthn.helpers import base64url_to_bytes, bytes_to_base64url
from webauthn.helpers.structs import (
    AuthenticatorSelectionCriteria,
    PublicKeyCredentialDescriptor,
    ResidentKeyRequirement,
    UserVerificationRequirement,
)

RP_ID = os.environ["PHONE_APPROVAL_RP_ID"]
ORIGIN = f"https://{RP_ID}"
STATE = os.path.join(os.environ["STATE_DIRECTORY"], "credentials.json")
SOCKET = os.path.join(os.environ["RUNTIME_DIRECTORY"], "pam.sock")
PORT = int(os.environ["PHONE_APPROVAL_PORT"])
ENROLL_SECONDS = 600
MAX_APPROVE_SECONDS = 120
USER_RE = re.compile(r"^[a-z_][a-z0-9_-]*$")

lock = threading.Lock()
pending = {}  # request id -> dict


def load_credentials():
    try:
        with open(STATE) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def save_credentials(creds):
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(creds, f, indent=2)
    os.replace(tmp, STATE)


def new_request(kind, user, seconds, **extra):
    rid = secrets.token_urlsafe(18)
    req = {
        "kind": kind,
        "user": user,
        "expires": time.monotonic() + seconds,
        "challenge": secrets.token_bytes(32),
        "done": threading.Event(),
        "result": "timeout",
        **extra,
    }
    with lock:
        pending[rid] = req
    return rid, req


def take(rid, kind):
    """The live request with this id and kind, or None."""
    with lock:
        req = pending.get(rid)
        if req is None or req["kind"] != kind or req["done"].is_set():
            return None
        if time.monotonic() > req["expires"]:
            return None
        return req


def finish(req, result):
    req["result"] = result
    req["done"].set()


# --- Unix socket for the PAM helper and the enroll command (root only) ---


class PamHandler(socketserver.StreamRequestHandler):
    def send(self, obj):
        self.wfile.write((json.dumps(obj) + "\n").encode())
        self.wfile.flush()

    def handle(self):
        try:
            msg = json.loads(self.rfile.readline(4096))
            user = msg["user"]
            if not USER_RE.match(user):
                return self.send({"error": "bad-user"})
            if msg["op"] == "approve":
                if not load_credentials().get(user):
                    return self.send({"error": "not-enrolled"})
                seconds = min(float(msg.get("timeout", 30)), MAX_APPROVE_SECONDS)
                reason = str(msg.get("reason", ""))[:300]
                rid, req = new_request("approve", user, seconds, reason=reason)
                path = "r"
            elif msg["op"] == "enroll":
                seconds = ENROLL_SECONDS
                rid, req = new_request("enroll", user, seconds)
                path = "e"
            else:
                return self.send({"error": "bad-op"})
            try:
                self.send({"url": f"{ORIGIN}/{path}/{rid}"})
                req["done"].wait(seconds)
                self.send({"result": req["result"]})
            finally:
                with lock:
                    pending.pop(rid, None)
        except (ValueError, KeyError, OSError) as e:
            try:
                self.send({"error": type(e).__name__})
            except OSError:
                pass


class UnixServer(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True


# --- HTTP, reached from the phone through Caddy ---

PAGE = """<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>erebor approval</title>
<style>
 body {{ font: 17px system-ui, sans-serif; margin: 0; padding: 2rem 1.2rem;
        background: #111418; color: #e8eaed; }}
 h1 {{ font-size: 1.3rem; margin: 0 0 1rem; }}
 .reason {{ font-family: ui-monospace, monospace; background: #1d2228;
           padding: .8rem; border-radius: .6rem; word-break: break-all; }}
 button {{ display: block; width: 100%; font-size: 1.1rem; padding: 1rem;
          margin-top: 1rem; border: 0; border-radius: .8rem; }}
 #ok {{ background: #4c8bf5; color: white; }}
 #no {{ background: #2a3038; color: #e8eaed; }}
 #status {{ margin-top: 1.2rem; min-height: 1.5em; }}
</style></head><body>
<h1>{title}</h1>
{body}
<div id="status"></div>
<script>
const opts = {options};
const kind = "{kind}";
const b64u = {{
  dec: s => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/")), c => c.charCodeAt(0)),
  enc: b => btoa(String.fromCharCode(...new Uint8Array(b))).replace(/\\+/g, "-").replace(/\\//g, "_").replace(/=+$/, ""),
}};
const status = t => document.getElementById("status").textContent = t;
function done(t) {{ status(t); document.querySelectorAll("button").forEach(b => b.disabled = true); }}
async function post(path, body) {{
  const r = await fetch(location.pathname + path, {{method: "POST",
    headers: {{"Content-Type": "application/json"}}, body: JSON.stringify(body || {{}})}});
  return [r.ok, await r.text()];
}}
async function go() {{
  try {{
    opts.challenge = b64u.dec(opts.challenge);
    let cred, body;
    if (kind === "enroll") {{
      opts.user.id = b64u.dec(opts.user.id);
      (opts.excludeCredentials || []).forEach(c => c.id = b64u.dec(c.id));
      cred = await navigator.credentials.create({{publicKey: opts}});
      body = {{id: cred.id, rawId: b64u.enc(cred.rawId), type: cred.type,
        response: {{clientDataJSON: b64u.enc(cred.response.clientDataJSON),
                   attestationObject: b64u.enc(cred.response.attestationObject),
                   transports: cred.response.getTransports ? cred.response.getTransports() : []}},
        clientExtensionResults: cred.getClientExtensionResults()}};
    }} else {{
      (opts.allowCredentials || []).forEach(c => c.id = b64u.dec(c.id));
      cred = await navigator.credentials.get({{publicKey: opts}});
      body = {{id: cred.id, rawId: b64u.enc(cred.rawId), type: cred.type,
        response: {{clientDataJSON: b64u.enc(cred.response.clientDataJSON),
                   authenticatorData: b64u.enc(cred.response.authenticatorData),
                   signature: b64u.enc(cred.response.signature),
                   userHandle: cred.response.userHandle ? b64u.enc(cred.response.userHandle) : null}},
        clientExtensionResults: cred.getClientExtensionResults()}};
    }}
    const [ok, text] = await post(kind === "enroll" ? "" : "/approve", body);
    done(text);
  }} catch (e) {{ status("Not approved: " + e.message); }}
}}
document.getElementById("ok").onclick = go;
const no = document.getElementById("no");
if (no) no.onclick = async () => {{ const [, t] = await post("/deny"); done(t); }};
</script></body></html>"""


class WebHandler(BaseHTTPRequestHandler):
    server_version = "phone-approval"

    def log_message(self, fmt, *args):
        print("http:", fmt % args, flush=True)

    def reply(self, code, text, ctype="text/plain; charset=utf-8"):
        data = text.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Frame-Options", "DENY")
        self.end_headers()
        self.wfile.write(data)

    def parts(self):
        return [p for p in self.path.split("?")[0].split("/") if p]

    def do_GET(self):
        p = self.parts()
        if len(p) != 2 or p[0] not in ("r", "e"):
            return self.reply(404, "Not found.")
        kind = "approve" if p[0] == "r" else "enroll"
        req = take(p[1], kind)
        if req is None:
            return self.reply(410, "This request has expired or was already answered.")
        creds = load_credentials().get(req["user"], [])
        if kind == "approve":
            options = generate_authentication_options(
                rp_id=RP_ID,
                challenge=req["challenge"],
                timeout=int(max(1, req["expires"] - time.monotonic()) * 1000),
                allow_credentials=[
                    PublicKeyCredentialDescriptor(id=base64url_to_bytes(c["id"])) for c in creds
                ],
                user_verification=UserVerificationRequirement.REQUIRED,
            )
            title = f"Approve as {html.escape(req['user'])} on erebor?"
            body = (
                f'<div class="reason">{html.escape(req["reason"] or "sudo")}</div>'
                '<button id="ok">Approve with fingerprint</button>'
                '<button id="no">Deny</button>'
            )
        else:
            options = generate_registration_options(
                rp_id=RP_ID,
                rp_name="erebor approval",
                user_name=req["user"],
                user_id=req["user"].encode(),
                challenge=req["challenge"],
                timeout=ENROLL_SECONDS * 1000,
                authenticator_selection=AuthenticatorSelectionCriteria(
                    resident_key=ResidentKeyRequirement.DISCOURAGED,
                    user_verification=UserVerificationRequirement.REQUIRED,
                ),
                exclude_credentials=[
                    PublicKeyCredentialDescriptor(id=base64url_to_bytes(c["id"])) for c in creds
                ],
            )
            title = f"Add this phone for {html.escape(req['user'])} on erebor"
            body = (
                "<p>Creates a passkey on this phone that can approve sudo on erebor.</p>"
                '<button id="ok">Create passkey</button>'
            )
        page = PAGE.format(
            title=title,
            body=body,
            kind=kind,
            options=options_to_json(options).replace("</", "<\\/"),
        )
        self.reply(200, page, "text/html; charset=utf-8")

    def do_POST(self):
        p = self.parts()
        length = min(int(self.headers.get("Content-Length") or 0), 65536)
        raw = self.rfile.read(length)
        if self.headers.get("Origin") != ORIGIN:
            return self.reply(403, "Wrong origin.")
        if len(p) == 3 and p[0] == "r" and p[2] == "deny":
            req = take(p[1], "approve")
            if req is None:
                return self.reply(410, "Expired.")
            finish(req, "denied")
            return self.reply(200, "Denied. erebor falls back to the next method.")
        if len(p) == 3 and p[0] == "r" and p[2] == "approve":
            return self.approve(p[1], raw)
        if len(p) == 2 and p[0] == "e":
            return self.enroll(p[1], raw)
        return self.reply(404, "Not found.")

    def approve(self, rid, raw):
        req = take(rid, "approve")
        if req is None:
            return self.reply(410, "Expired.")
        try:
            cred = json.loads(raw)
            with lock:
                creds = load_credentials()
                mine = creds.get(req["user"], [])
                stored = next(c for c in mine if c["id"] == cred["id"])
                result = verify_authentication_response(
                    credential=cred,
                    expected_challenge=req["challenge"],
                    expected_rp_id=RP_ID,
                    expected_origin=ORIGIN,
                    credential_public_key=base64url_to_bytes(stored["public_key"]),
                    credential_current_sign_count=stored["sign_count"],
                    require_user_verification=True,
                )
                stored["sign_count"] = result.new_sign_count
                stored["last_used"] = int(time.time())
                save_credentials(creds)
        except Exception as e:  # any verification failure is a refusal
            print(f"approve {req['user']}: rejected: {e!r}", flush=True)
            return self.reply(400, "Verification failed.")
        print(f"approve {req['user']}: approved: {req['reason']}", flush=True)
        finish(req, "approved")
        return self.reply(200, "Approved.")

    def enroll(self, rid, raw):
        req = take(rid, "enroll")
        if req is None:
            return self.reply(410, "Expired.")
        try:
            result = verify_registration_response(
                credential=json.loads(raw),
                expected_challenge=req["challenge"],
                expected_rp_id=RP_ID,
                expected_origin=ORIGIN,
                require_user_verification=True,
            )
            with lock:
                creds = load_credentials()
                creds.setdefault(req["user"], []).append(
                    {
                        "id": bytes_to_base64url(result.credential_id),
                        "public_key": bytes_to_base64url(result.credential_public_key),
                        "sign_count": result.sign_count,
                        "created": int(time.time()),
                        "agent": self.headers.get("User-Agent", "")[:200],
                    }
                )
                save_credentials(creds)
        except Exception as e:
            print(f"enroll {req['user']}: failed: {e!r}", flush=True)
            finish(req, "failed")
            return self.reply(400, "Registration failed.")
        print(f"enroll {req['user']}: passkey added", flush=True)
        finish(req, "enrolled")
        return self.reply(200, "Passkey added. This phone can now approve sudo on erebor.")


def main():
    try:
        os.unlink(SOCKET)
    except FileNotFoundError:
        pass
    os.umask(0o077)  # the socket stays root/service only
    unix = UnixServer(SOCKET, PamHandler)
    threading.Thread(target=unix.serve_forever, daemon=True).start()
    web = ThreadingHTTPServer(("127.0.0.1", PORT), WebHandler)
    web.daemon_threads = True
    print(f"phone-approval: {ORIGIN} -> 127.0.0.1:{PORT}, socket {SOCKET}", flush=True)
    web.serve_forever()


if __name__ == "__main__":
    main()
