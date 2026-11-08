# NixOS `erebor` maintenance instructions

This repository is the authoritative declarative configuration for the
installed NixOS system. Maintain the system incrementally, preserve the
working Windows installation, and verify every material change.

## Parallel agents

Several agents may change this repository at once. To avoid overwriting each
other:

- Work in your own worktree: `scripts/erebor-worktree <task>` creates
  `~/nixos-wt/<task>` on branch `agent/<task>`. Edit, check and build there
  with `scripts/erebor-rebuild build`. Do not edit `/etc/nixos` directly while
  another agent may be working in it.
- Before merging a refactor, run `scripts/erebor-diff` in your worktree (it
  compares the built system with `master`) and quote its tier (identical,
  equivalent or different) in the changelog entry.
- Activate only from `/etc/nixos` on `master`, through
  `scripts/erebor-rebuild test|switch`. It refuses other checkouts, holds a
  lock so only one rebuild runs at a time, and uses the setuid sudo.
  Activating any other tree rolls back changes that are on `master` but not in
  that tree.
- To land work: commit on your branch, run `git -C /etc/nixos merge
  agent/<task>` (rebase first if it does not merge cleanly), activate, verify,
  then `git worktree remove --force ~/nixos-wt/<task>` and delete the branch.
- `SYSTEM_CHANGELOG.md` and `SYSTEM_TODO.md` merge with `merge=union`, which
  keeps both sides. After a merge, check that edits to the same entry did not
  leave duplicated lines.
- To claim a new `SYS-NNN` ID, commit the task stub to `master` first, so two
  agents never pick the same number.
- Uncommitted changes in `/etc/nixos` that you did not make belong to another
  agent. Leave them out of your commits and do not reset them;
  `erebor-rebuild` lists them before activating.

## Repository layout and other machines

- The flake uses the dendritic pattern: `flake.nix` loads every `.nix` file
  under `modules/` with import-tree as a flake-parts module. Each file adds
  NixOS and/or Home Manager aspects (`flake.modules.nixos.<name>`,
  `flake.modules.homeManager.<name>`). A feature that spans both (Umbriel,
  Noctalia, Niri, Vicinae, Darkly, xremap, …) keeps both halves in one file.
  Flake inputs reach modules by closure (`{ inputs, ... }:` around the
  aspect); do not add `specialArgs`. Paths with a `_`-prefixed component
  (e.g. `_hardware-configuration.nix`) are not loaded as flake-parts modules.
- `modules/hosts/<name>/` holds only what is specific to one machine:
  `default.nix` builds `nixosConfigurations.<name>` from aspects and sets its
  `my.*` values, next to its hardware, boot and storage.
  `modules/hosts/template/` is the starting point for a new machine and is
  evaluated (never deployed) as `nixosConfigurations.template`, which proves
  optional features switch off.
- `modules/my.nix` declares the per-machine settings (user, domain, LAN
  interface, and feature toggles such as ambilight, YubiKey, Mac approval and
  NanoKVM). Shared modules read `config.my.*`; do not hard-code erebor's user,
  domain, addresses or device names in them. Features stay switched by these
  toggles, not by which aspects a host imports.
- `modules/workstation/default.nix` is the shared desktop profile (the
  `workstation` aspect, which imports every shared aspect; add new shared
  aspects there). `modules/home/janzon.nix` is the Home Manager integration
  and janzon's profile, which lists the `homeManager` aspects; topic aspects
  are in `modules/home/`. `home/<app>/` holds the dotfiles they deploy.
- Hardware-specific aspects (`xremap`, `nvidia`, `windows-vm`,
  `looking-glass`) are imported per host.
- Module order is breadth-first by import depth, so moving a definition into
  another aspect can reorder list options (packages, overlays, graphics
  drivers). Check with `scripts/erebor-diff` after moving code between
  aspects.

## Before changing the system

- Read the relevant Nix files and modules before editing them.
- Check the current generation, mounts, boot entries, and failed units when
  the change affects system state, boot, storage, or services.
- Run `nix flake check` and an appropriate `nixos-rebuild dry-build` or
  `nixos-rebuild build` before activation.
- Keep changes small and declarative. Do not duplicate facts already derived
  from the flake or modules in the operational documents.
- Stop and ask the user when the requested change is ambiguous, conflicts with
  this file, or could affect Windows, the ESP, or user data.

## Storage and boot safety

- Treat the target Btrfs filesystem as identified by UUID
  `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and the ESP by filesystem UUID
  `38B5-8386`; never identify them by transient `/dev/sdX` or `/dev/nvme...`
  names.
- Never run partitioning, formatting, signature-wiping, or recursive deletion
  commands for this system without explicit user authorization and a reviewed
  recovery plan.
- Preserve Windows UEFI files and entries. Do not change the
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
  Put new entries directly below its header. Record versions as dated
  evidence, not live state.
- `SYSTEM_CHANGELOG.md` holds only the current month. The first entry of a new
  month first moves the previous month's entries, unchanged and newest first,
  to `changelog/YYYY-MM.md`, adds that file to the header's list of earlier
  months, and rewrites links to moved entries (`SYSTEM_CHANGELOG.md#…` becomes
  `changelog/YYYY-MM.md#…`; links inside the archive gain `../`). Check that
  every link still resolves. Archived months are history: do not edit them
  except to fix links.
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

## Desktop configuration (live)

- Umbriel is the primary compositor session (`XDG_CURRENT_DESKTOP=umbriel`);
  Niri is still configured but is not the main session. Desktop and keybind
  changes normally belong in Umbriel.
- `home/umbriel/config.toml`, `home/noctalia/config.toml` and
  `home/niri/config.kdl` are live: Home Manager links
  `~/.config/{umbriel,noctalia,niri}/…` to the files in `my.flakePath`
  (`/etc/nixos`) with out-of-store symlinks (`modules/{umbriel,noctalia,niri}.nix`).
  Saving the file in `/etc/nixos` applies it; no rebuild or activation is
  needed. Rebuilds are only needed when the link itself or the Nix code
  around it changes. Edit the files, never the `~/.config` links.
- Because `/etc/nixos` is the live copy, an edit there takes effect as soon as
  it is written: make the change in your worktree, commit, then merge to
  `master` as usual; the merge is the moment it goes live. Rollback is `git`
  (revert or check out the previous version), not a previous generation.
- A config that fails to parse does not crash the session: Umbriel and Niri
  keep the last good config (Niri shows "Failed to parse the config file").
  So a change is done only after you confirm it applied: Umbriel's
  inspection commands (`umbriel submap`, `umbriel outputs`), `niri validate`
  and `niri msg action load-config-file`, or by trying the behavior; anything
  visible is confirmed with a screenshot.
- Keybinding, output, input, idle and portal changes can take down the
  session the user is looking at: do not experiment with them live; reason
  them out first and have a rollback ready.
- Noctalia's settings window saves to `~/.local/state/noctalia/settings.toml`,
  which overrides `config.toml`. When the user asks to sync or save their
  Noctalia settings into the config, follow
  [docs/noctalia-settings.md](docs/noctalia-settings.md).

## Secrets and source control

- Keep passwords, Wi-Fi credentials, browser profiles, tokens, private keys,
  and other secrets out of this repository and the Nix store.
- Keep the flake lock file committed and review `git diff` before committing.
- Do not commit generated secrets, machine-specific credentials, or unrelated
  user changes.
- After a verified important system change, commit the relevant configuration
  and changelog changes in Git before declaring the work complete.
- Run `nix fmt` before committing (nixfmt, RFC 166 style; it formats every
  `.nix` file outside `apps/`). `nix flake check` fails on unformatted files.
- Keep commits focused and descriptive; check `git status` after committing
  and leave unrelated user changes untouched.
