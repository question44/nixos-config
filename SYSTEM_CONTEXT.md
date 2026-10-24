# System context for NixOS `erebor` (flake target `moria`)

Verify live state before acting; this file is not a system inventory. Fedora
was retired on 2026-10-23 at the user's explicit request after its active
root/home subvolumes were found missing. Shared service data remains in use
by NixOS. See SYS-025 and its dated change record.

This document becomes the NixOS-side operational memory after the parallel
installation. Verify live state before acting and do not record passwords,
tokens, private keys, browser profiles, Wi-Fi credentials, or other secrets.
Keep it concise: retain only important information relevant now, and remove an
entry when it becomes obsolete, superseded, or no longer applies. Historical
changes belong in [SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md), not here.
Unfinished work and verification checks belong in
[SYSTEM_TODO.md](SYSTEM_TODO.md); do not duplicate task status here.

## What belongs here

- Non-declarative runtime facts verified on this host.
- Intentional exceptions or manual state that cannot be expressed in the Nix
  flake/modules.
- External recovery locations, hardware quirks, and safe validation steps.
- Reusable, verified operational pitfalls and their prevention/recovery.

## What does not belong here

- Packages, service definitions, mount topology, bootloader settings, desktop
  configuration, or any other state that can be derived from the flake and
  modules. The repository is authoritative for those.
- Secrets or one-off command history.

## Reusable operational pitfalls

- The private dashboard submodule needs GitHub SSH access when Nix fetches a
  clean Git source. Evaluate/build as the SSH-authenticated user; for deployment,
  `nixos-rebuild test --sudo --flake /etc/nixos#moria` reserves sudo for activation.
  The installed rebuild command supports `--sudo`; do not copy SSH keys to root
  or into the Nix store. See SYS-037 for the tested clone/build evidence.

- GRUB migration retains firmware **Linux Boot Manager** (0004), loading
  `/EFI/systemd/systemd-bootx64.efi`, and its existing generation menu as a
  recovery path. GRUB also offers a systemd-boot recovery chainload. Verified
  preserved at installation on 2026-10-23; see SYS-029 for first-boot acceptance.

- Windows VM disk now resides on Crucial UUID `604F-A363` at
  `/srv/external/crucial/windows11.qcow2`. The live local image was removed;
  NixOS recovery snapshots retain its blocks. Older domain XML must have its
  source path updated before reuse, or be paired with a restored original
  disk/NVRAM/TPM. See [Windows VM recovery](WINDOWS_VM.md#disk-location-and-recovery).

- Fedora boot files and original firmware entry descriptions were archived
  under root-only `/var/lib/system-recovery/fedora-retirement-20261023`.
  These archives do not contain the deleted Fedora root snapshot. The
  pre-retirement NixOS recovery snapshot is
  `/btrfs-top/nixos-root-pre-fedora-retirement-20261023` (ID 656, ro=true).
  Rolling back to generation 200 may restore an obsolete Fedora menu entry;
  the current declarative configuration intentionally omits that entry.
- Interactive sudo supports YubiKey authentication through a PTY; noninteractive
  sudo can report that a password is required even when a YubiKey is available.
- A newly added kernel module is not found by default modprobe after a NixOS
  test activation because it searches `/run/booted-system/kernel-modules`.
  For a module built against the running kernel, load it with
  `modprobe --dirname /run/current-system/kernel-modules <module>`.
- NixOS libvirt copies qemu.conf through libvirtd-config.service at daemon
  startup. After changing its device ACL, restart libvirtd to load it;
  test activation alone leaves an already-running daemon on its old config.
- Windows Looking Glass IDD needs **Force indirect copy** on this UHD 770:
  direct transport produced missing strips/blocks even with full-frame copies.
  The guest registry workaround and recovery locations are in WINDOWS_VM.md.
