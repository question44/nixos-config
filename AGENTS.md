# NixOS `erebor` maintenance instructions

This repository is the authoritative declarative configuration for the
installed NixOS system. Maintain the system incrementally, preserve the
working Windows installation, and verify every material change.

## Rules that always apply

- Work in your own worktree (`scripts/erebor-worktree <task>`), never
  directly in `/etc/nixos`; leave changes you did not make alone.
- Activate only from `/etc/nixos` on `master` through
  `scripts/erebor-rebuild test|switch`. Build with
  `scripts/erebor-rebuild build` and compare with `scripts/erebor-diff`
  first; quote its tier in the changelog.
- Read the relevant Nix files before editing. Keep changes small and
  declarative; do not duplicate facts derived from the flake in the
  operational documents.
- Stop and ask the user when a change is ambiguous, conflicts with this file,
  or could affect Windows, the ESP or user data.
- Never run partitioning, formatting, signature-wiping or recursive deletion
  commands without explicit user authorization and a reviewed recovery plan.
  Identify the Btrfs filesystem and the ESP by UUID only.
- Do not reboot after a material change without a read-back checkpoint in
  `SYSTEM_CHANGELOG.md`.
- A change is complete when it is activated and verified, recorded in
  `SYSTEM_CHANGELOG.md`, and committed; a build alone is not activation.

## Skills: read the one that matches the task

Procedures live in `.claude/skills/<name>/SKILL.md`. Read the matching one
before acting; each holds the full rules for its area.

| Skill | Use it when |
|---|---|
| `parallel-agents` | creating a worktree, comparing with `erebor-diff`, merging into `master`, claiming a `SYS-NNN` ID |
| `activation-and-checkpoints` | activating, rebooting, or touching boot, ESP, storage, subvolumes or Windows |
| `system-records` | writing `SYSTEM_CHANGELOG.md`, `SYSTEM_TODO.md` or `SYSTEM_CONTEXT.md`, month rollover, `[PENDING]` checkpoints |
| `desktop-config` | changing Umbriel, Noctalia or Niri (their configs are live from `/etc/nixos`) |

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
