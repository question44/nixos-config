# NixOS `moria` maintenance instructions

This repository is the authoritative declarative configuration for the
installed NixOS system. Maintain the system incrementally, preserve the
working Fedora and Windows installations, and verify every material change.

## Before changing the system

- Read the relevant Nix files and modules before editing them.
- Check the current generation, mounts, boot entries, and failed units when
  the change affects system state, boot, storage, or services.
- Run `nix flake check` and an appropriate `nixos-rebuild dry-build` or
  `nixos-rebuild build` before activation.
- Keep changes small and declarative. Do not duplicate facts already derived
  from the flake or modules in the operational documents.
- Stop and ask the user when the requested change is ambiguous, conflicts with
  this file, or could affect Fedora, Windows, the ESP, or user data.

## Storage and boot safety

- Treat the target Btrfs filesystem as identified by UUID
  `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and the ESP by filesystem UUID
  `38B5-8386`; never identify them by transient `/dev/sdX` or `/dev/nvme...`
  names.
- Never run partitioning, formatting, signature-wiping, or recursive deletion
  commands for this system without explicit user authorization and a reviewed
  recovery plan.
- Preserve Fedora and Windows UEFI files and entries. Do not change the
  firmware default or remove another operating system's boot entry as part of
  routine maintenance.
- Before any material boot, ESP, filesystem, subvolume, or reboot operation,
  create and verify an important Snapper snapshot when applicable, record a
  pending checkpoint, and verify the recovery path.

## Applying and verifying changes

- Prefer `nixos-rebuild test` for live validation and use `switch` only when
  the change is verified and the user has requested activation or activation
  is the normal completion of the task.
- Before rebooting after a material change, write and read back a checkpoint
  in `SYSTEM_CHANGELOG.md` with the exact generation, validation performed,
  current risks, and mandatory next action. Do not reboot with an unresolved
  pending safety check.
- After activation or reboot, verify the affected services, generation,
  mounts, bootability, and user-facing behavior. Record the result before
  declaring the change complete.
- Use `SYSTEM_CHANGELOG.md` for completed changes and pending operations;
  prefix active work with **[PENDING]** and update that same entry to
  **[COMPLETED]** with verification results. Keep `SYSTEM_CONTEXT.md` concise
  and limited to current non-declarative facts, recovery information, and
  verified operational pitfalls. `INSTALLATION_LOG.md` is the historical
  installation record and should not be used for routine maintenance history.

## System design boundaries

- Preserve the established NixOS design: NVIDIA, Niri, Noctalia, Ghostty,
  Wayland/portal/audio support, ungoogled Chromium, and Oo7 as the desktop
  Secret Service provider.
- Launch Niri through `niri-session` and launch Noctalia from Niri. Do not add
  competing ad-hoc services or reintroduce GNOME Keyring or KWallet without
  explicit user direction and a documented design decision.
- Add services, packages, dotfiles, containers, and personal data only when
  explicitly requested. Prefer one change at a time with build, activation,
  and live verification.

## Niri configuration workflow

- The canonical Niri configuration is
  `/etc/nixos/home/niri/config.kdl`; Home Manager deploys it to
  `/home/janzon/.config/niri/config.kdl`.
- Do not edit the deployed file in `/home/janzon/.config/niri/` directly; it
  is a Nix store symlink and will be replaced on the next activation.
- After changing Niri settings, run `nix flake check`,
  `nixos-rebuild dry-build --flake /etc/nixos#moria`, and then
  `sudo nixos-rebuild switch --flake /etc/nixos#moria`.
- Restart Niri with `niri msg action quit` and log back in to load the new
  configuration. Verify the affected behavior before declaring the change
  complete.

## Secrets and source control

- Keep passwords, Wi-Fi credentials, browser profiles, tokens, private keys,
  and other secrets out of this repository and the Nix store.
- Keep the flake lock file committed and review `git diff` before committing.
- Do not commit generated secrets, machine-specific credentials, or unrelated
  user changes.
