"""Notify the desktop while pam-u2f holds its touch-request file open."""

import ctypes
import os
import select
import signal
import struct
import subprocess
import sys


OPEN = 0x20
CLOSE = 0x08 | 0x10
OVERFLOW = 0x4000
EVENT = struct.Struct("iIII")
pending_name = b"pam-u2f-authpending"
stopping = False


def stop(_signum, _frame):
    global stopping
    stopping = True


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, timeout=5, check=True)


class Prompt:
    def __init__(self, sound):
        self.sound = sound
        self.notification_id = None
        self.player = None

    def show(self):
        try:
            result = run(
                "notify-send", "--print-id", "--app-name=YubiKey",
                "--urgency=critical", "--expire-time=0", "--icon=dialog-password",
                "--hint=boolean:transient:true", "--hint=boolean:suppress-sound:true",
                "Touch your YubiKey", "Authentication is waiting for your touch.",
            )
            self.notification_id = int(result.stdout.strip())
            print(f"Touch requested; notification {self.notification_id}", flush=True)
        except (subprocess.SubprocessError, OSError, ValueError) as exc:
            print(f"Could not display touch notification: {exc}", file=sys.stderr)
        try:
            self.player = subprocess.Popen(["pw-play", self.sound])
        except OSError as exc:
            print(f"Could not play touch sound: {exc}", file=sys.stderr)

    def close(self):
        if self.notification_id is not None:
            try:
                run(
                    "gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                    "--object-path", "/org/freedesktop/Notifications",
                    "--method", "org.freedesktop.Notifications.CloseNotification",
                    str(self.notification_id),
                )
                print(f"Touch wait ended; closed notification {self.notification_id}", flush=True)
            except (subprocess.SubprocessError, OSError) as exc:
                print(f"Could not close touch notification: {exc}", file=sys.stderr)
            self.notification_id = None
        if self.player is not None:
            if self.player.poll() is None:
                self.player.terminate()
            try:
                self.player.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.player.kill()
                self.player.wait()
            self.player = None


def main():
    libc = ctypes.CDLL(None, use_errno=True)
    fd = libc.inotify_init1(os.O_CLOEXEC | os.O_NONBLOCK)
    if fd < 0:
        raise OSError(ctypes.get_errno(), "inotify_init1 failed")
    # Watching the directory also works when PAM creates the file after login.
    runtime = os.fsencode(os.environ["XDG_RUNTIME_DIR"])
    if libc.inotify_add_watch(fd, runtime, OPEN | CLOSE) < 0:
        os.close(fd)
        raise OSError(ctypes.get_errno(), "inotify_add_watch failed")
    prompt = Prompt(sys.argv[1])
    waiting = 0
    print("Watching PAM YubiKey touch requests", flush=True)
    try:
        while not stopping:
            if not select.select([fd], [], [], 0.5)[0]:
                continue
            events = os.read(fd, 65536)
            offset = 0
            while offset < len(events):
                _, mask, _, length = EVENT.unpack_from(events, offset)
                name = events[offset + EVENT.size:offset + EVENT.size + length].rstrip(b"\0")
                offset += EVENT.size + length
                if mask & OVERFLOW:
                    # Restart with a clean queue instead of retaining a stale prompt.
                    raise RuntimeError("inotify queue overflow")
                if name != pending_name:
                    continue
                if mask & OPEN:
                    if waiting == 0:
                        prompt.show()
                    waiting += 1
                if mask & CLOSE:
                    waiting = max(0, waiting - 1)
                    if waiting == 0:
                        prompt.close()
    finally:
        prompt.close()
        os.close(fd)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    main()
