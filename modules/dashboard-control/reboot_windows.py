"""Select the existing Windows GRUB entry once, then request an inhibited reboot."""

from pathlib import Path
import re
import subprocess
import sys

ESP_UUID = "38B5-8386"
ROOT_UUID = "5be9be17-20c9-4a47-ba2d-6adf1ceb4c55"
ENTRY = "Windows Boot Manager"
ENV = "/boot/grub/grubenv"


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=15).stdout


def environment():
    return dict(line.split("=", 1) for line in run("grub-editenv", ENV, "list").splitlines()
                if "=" in line)


def check():
    for mount, uuid in [("/", ROOT_UUID), ("/boot", ESP_UUID)]:
        if run("findmnt", "--noheadings", "--output", "UUID", "--mountpoint", mount).strip().lower() != uuid.lower():
            raise RuntimeError(f"Unexpected filesystem at {mount}")
    for loader in ["Microsoft/Boot/bootmgfw.efi", "NixOS-boot/grubx64.efi",
                   "systemd/systemd-bootx64.efi"]:
        if not Path("/boot/EFI", loader).is_file():
            raise RuntimeError(f"Missing EFI loader: {loader}")
    config = Path("/boot/grub/grub.cfg").read_text()
    entries = re.findall(r'^menuentry "Windows Boot Manager" \{\n(.*?)^\}', config, re.M | re.S)
    if (len(entries) != 1 or f"--fs-uuid --set=root {ESP_UUID}" not in entries[0]
            or "chainloader /EFI/Microsoft/Boot/bootmgfw.efi" not in entries[0]
            or 'set default="${next_entry}"' not in config
            or "save_env next_entry" not in config):
        raise RuntimeError("Expected Windows entry or one-time GRUB selection is missing")
    if environment().get("next_entry"):
        raise RuntimeError("Another one-time boot selection is already pending")


def reboot():
    check()
    try:
        run("grub-editenv", ENV, "set", f"next_entry={ENTRY}")
        if environment().get("next_entry") != ENTRY:
            raise RuntimeError("Windows one-time selection could not be verified")
        run("sync", "-f", ENV)
        # Bit 0 honours shutdown inhibitors even for this privileged service.
        run("busctl", "--system", "--allow-interactive-authorization=no", "call",
            "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "RebootWithFlags", "t", "1")
    except Exception:
        if environment().get("next_entry") == ENTRY:
            run("grub-editenv", ENV, "unset", "next_entry")
            run("sync", "-f", ENV)
            if environment().get("next_entry"):
                raise RuntimeError("Failed to clear the one-time boot selection")
        raise


if __name__ == "__main__":
    if sys.argv[1:] == ["--check"]:
        check()
        print("Windows boot prerequisites verified; boot selection unchanged.")
    elif sys.argv[1:]:
        raise SystemExit("Usage: reboot_windows.py [--check]")
    else:
        reboot()
