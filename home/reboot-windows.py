#!/run/current-system/sw/bin/python3
"""Select the Windows loader on the shared ESP for one boot, then reboot."""
import argparse
from pathlib import Path
import re
import subprocess
import sys

EFIBOOTMGR = '/run/current-system/sw/bin/efibootmgr'
SUDO = '/run/wrappers/bin/sudo'
SYSTEMCTL = '/run/current-system/sw/bin/systemctl'
WINDOWS_ESP = '01efe05e-d3eb-4ebd-a310-6fb83809c645'


def run(*args):
    return subprocess.check_output(args, text=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dry-run', action='store_true', help='Validate and show the target without changing anything')
    args = parser.parse_args()
    if not Path('/dev/disk/by-partuuid', WINDOWS_ESP).exists():
        raise RuntimeError('The Windows EFI partition is missing.')
    entries = run(EFIBOOTMGR)
    targets = []
    for line in entries.splitlines():
        match = re.match(r'^Boot([0-9A-Fa-f]{4})\*\s+Windows Boot Manager\s+', line)
        if match and WINDOWS_ESP in line.lower() and r'\efi\microsoft\boot\bootmgfw.efi' in line.lower():
            targets.append(match.group(1).upper())
    if len(targets) != 1:
        raise RuntimeError('Expected exactly one active Windows entry on the configured EFI partition.')
    target = targets[0]
    print(f'Windows Boot Manager: Boot{target} (one boot only)', flush=True)
    if args.dry_run:
        print('Dry run: no boot variables changed; no reboot requested.')
        return
    subprocess.run([SUDO, '-n', EFIBOOTMGR, '--bootnext', target], check=True)
    if not re.search(rf'^BootNext: {target}$', run(EFIBOOTMGR), re.MULTILINE):
        raise RuntimeError('BootNext verification failed; refusing to reboot.')
    print('Rebooting into Windows...', flush=True)
    subprocess.run([SUDO, '-n', SYSTEMCTL, 'reboot'], check=True)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as exc:
        print(f'reboot-windows: {exc}', file=sys.stderr)
        sys.exit(1)
