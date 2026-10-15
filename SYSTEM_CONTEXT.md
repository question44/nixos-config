# System context for NixOS `moria`

Last inspected: 2026-10-14. NixOS 26.05 is installed and currently booted
from the `nixos-root` subvolume. Initial NixOS boot and desktop checks passed,
and Fedora was subsequently verified intact from its firmware entry.

This document becomes the NixOS-side operational memory after the parallel
installation. Verify live state before acting and do not record passwords,
tokens, private keys, browser profiles, Wi-Fi credentials, or other secrets.
Keep it concise: retain only important information relevant now, and remove an
entry when it becomes obsolete, superseded, or no longer applies. Historical
changes belong in `SYSTEM_CHANGELOG.md`, not here.

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

- The installed Nix CLI has `nix-command` disabled by default. Run flake
  commands as `nix --extra-experimental-features 'nix-command flakes' flake
  <subcommand>` (for example, `flake check`) unless the feature is enabled in
  the environment.
