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
