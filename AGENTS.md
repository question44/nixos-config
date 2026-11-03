# NixOS `erebor` maintenance instructions

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
- Follow the record ownership and closure rules below.

## System records and task tracking

- Nix files define intended configuration. Avoid duplicating package, service,
  mount and version inventories in operational documents.
- `SYSTEM_CHANGELOG.md` records dated changes: what changed and why, activation
  outcome/generation when applicable, validation evidence, and explicit limits.
  Put new entries at the top. Record versions as dated evidence, not live state.
- `SYSTEM_TODO.md` is the single list of unfinished work. Give each task a stable
  `SYS-NNN` ID, status, review date, concrete completion condition and evidence
  links. Use OPEN for known work, ACTIVE for work underway, REVIEW for uncertain
  historical work, and DONE/CANCELLED with dated evidence/reason for closure.
  Keep IDs after closure; consolidate duplicate tasks by linking their records.
- `SYSTEM_CONTEXT.md` holds only current non-declarative facts, recovery knowledge
  and verified pitfalls. Remove superseded facts; link tasks rather than copying
  their status. Check live state before using any historical recovery path.
- Complete an implementation record once its stated scope is activated and
  required verification passes. A build alone does not prove activation.
  Track optional follow-ups and separate acceptance checks as linked tasks;
  explicitly required acceptance checks still block their own task's completion.
  Distinguish observed results, user confirmation, and untested behavior.
- Use `[PENDING]` changelog entries only for active material operations. Link the
  task; before disruptive operations record exact live generation, prechecks,
  recovery path, risks and next safe step, then read back the checkpoint. After
  verification, update the same entry with the outcome and resolve the task.
  Close failed/cancelled attempts with their actual result; do not imply success.
- Historical commands, approvals and checkpoints are evidence, not a current
  action queue. Resolve obsolete next-step instructions; preserve their dated
  context where useful. Never blindly replay an old reboot, activation or disk
  operation. `[RECORDED]` legacy entries have uncertain outcomes and link to a
  REVIEW task; reconcile newer evidence before doing system work.
- Keep entries concise. Routine inspections belong in a related task's evidence
  when they resolve a question, not a new changelog entry. Commit related records
  with the configuration change and leave unrelated working-tree edits alone.

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
  `nixos-rebuild dry-build --flake /etc/nixos#erebor`, and then
  `sudo nixos-rebuild switch --flake /etc/nixos#erebor`.
- Reload Niri's deployed configuration with `niri msg action load-config-file`
  and verify the affected behavior before declaring the change complete. A
  logout is only needed when a change cannot be applied by the live reload.

## Secrets and source control

- Keep passwords, Wi-Fi credentials, browser profiles, tokens, private keys,
  and other secrets out of this repository and the Nix store.
- Keep the flake lock file committed and review `git diff` before committing.
- Do not commit generated secrets, machine-specific credentials, or unrelated
  user changes.
- After a verified important system change, commit the relevant configuration
  and changelog changes in Git before declaring the work complete.
- Keep commits focused and descriptive; check `git status` after committing
  and leave unrelated user changes untouched.
