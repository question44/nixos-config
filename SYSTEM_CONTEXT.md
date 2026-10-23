# System context for NixOS `erebor` (flake target `moria`)

Verify live state before acting; this file is not a system inventory. Initial
NixOS boot and desktop checks passed, and Fedora was historically verified
intact from its firmware entry. That does not verify the later systemd-boot
chainload entry; its outstanding check is tracked in SYSTEM_TODO.md.

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

- systemd-boot activation removes a manually present fedora.conf if the built
  configuration omits its extraEntries setting. Preserve the existing Fedora
  extraEntries configuration when preparing isolated builds, and verify menu
  entries after activation. Generation 199 omitted it; its Fedora entry was
  manually restored. Do not replay that generation's bootloader setup without
  preserving the entry. See SYS-001 and the 2026-10-23 KDE Connect changelog.

- The installed Nix CLI has `nix-command` disabled by default. Run flake
  commands as `nix --extra-experimental-features 'nix-command flakes' flake
  <subcommand>` (for example, `flake check`) unless the feature is enabled in
  the environment.
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
