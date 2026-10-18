#!/usr/bin/env python3
"""Change Oo7 0.6's persistent keyring password through its PAM socket.

Passwords are read from the terminal and sent over the user's private socket;
they are never passed as command arguments or written to disk. This changes
keyrings matching the old password, not the Linux account password.
"""

import argparse
import getpass
import hashlib
import os
from pathlib import Path
import pwd
import socket
import struct
import subprocess
import tempfile
import time


def change_message(username, old, new):
    """Encode Oo7's little-endian D-Bus (ysayay) PAM ChangePassword message."""
    user = username.encode()
    message = bytearray([1])

    def align():
        message.extend(b"\0" * (-len(message) % 4))

    align()
    message.extend(struct.pack("<I", len(user)) + user + b"\0")
    for value in (old, new):
        align()
        message.extend(struct.pack("<I", len(value)) + value)
    return struct.pack("<I", len(message)) + message


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    if os.getuid() == 0:
        raise SystemExit("Run as your normal user, without sudo.")
    if not os.isatty(0):
        raise SystemExit("Run in an interactive terminal to enter passwords privately.")

    data_dir = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    keyring_dir = data_dir / "keyrings/v1"
    keyrings = sorted(keyring_dir.glob("*.keyring"))
    if not keyrings:
        raise SystemExit(f"No Oo7 v1 keyrings found in {keyring_dir}.")

    socket_path = Path(f"/run/user/{os.getuid()}/oo7-pam.sock")
    if not socket_path.exists():
        subprocess.run(
            ["systemctl", "--user", "restart", "oo7-daemon.service"], check=True
        )
        for _ in range(50):
            if socket_path.exists():
                break
            time.sleep(0.1)
    if not socket_path.exists():
        raise SystemExit("Oo7 did not create its PAM socket. Nothing changed.")

    old = getpass.getpass("Current keyring password (previous login password): ").encode()
    new = getpass.getpass("New keyring password (current login password): ").encode()
    confirm = getpass.getpass("Repeat new keyring password: ").encode()
    if not new or new != confirm:
        raise SystemExit("New passwords are empty or do not match. Nothing changed.")
    if old == new:
        raise SystemExit("Old and new passwords are identical. Nothing changed.")

    # Back up every persistent keyring: Oo7 changes all matching collections.
    # Keep backups outside v1 so the daemon never discovers them as collections.
    state_dir = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    backup_root = state_dir / "oo7-password-backups"
    backup_root.mkdir(mode=0o700, parents=True, exist_ok=True)
    backup_dir = Path(tempfile.mkdtemp(prefix="change-", dir=backup_root))
    before = {}
    for keyring in keyrings:
        content = keyring.read_bytes()
        before[keyring] = hashlib.sha256(content).digest()
        fd = os.open(backup_dir / keyring.name, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "wb") as destination:
            destination.write(content)
    print(f"Encrypted keyring backup: {backup_dir}")

    message = change_message(pwd.getpwuid(os.getuid()).pw_name, old, new)
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(10)
        connection.connect(str(socket_path))
        connection.sendall(message)
    old = new = confirm = message = None

    # The PAM protocol has no response; verify a persistent file actually changed.
    for _ in range(100):
        time.sleep(0.1)
        if any(hashlib.sha256(path.read_bytes()).digest() != digest
               for path, digest in before.items()):
            print("Encrypted keyring file updated; Linux account password unchanged.")
            print("Log out and back in to verify automatic unlocking.")
            return
    raise SystemExit(
        "No keyring update detected; password change is NOT confirmed.\n"
        "Check the old keyring password. The encrypted backup has been preserved."
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Oo7 password change failed: {error}") from None
    except (KeyboardInterrupt, EOFError):
        raise SystemExit("Cancelled.") from None
