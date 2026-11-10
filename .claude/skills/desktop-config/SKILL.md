---
name: desktop-config
description: Use when changing what the desktop shows or does - Umbriel keybinds, layout, outputs or window rules, Noctalia bar/widgets/theme, or syncing Noctalia's settings-window changes into the repo.
---

# Changing the desktop (Umbriel, Noctalia)

Umbriel is the only compositor session (`XDG_CURRENT_DESKTOP=umbriel`);
Niri was removed on 2026-11-08 (SYS-094).

## The live layer

These files are linked live: Home Manager points `~/.config/…` at the file in
`my.flakePath` (`/etc/nixos`) with an out-of-store symlink.

| File in the repo | Linked as | Module |
|---|---|---|
| `home/umbriel/config.toml` | `~/.config/umbriel/config.toml` | `modules/umbriel.nix` |
| `home/noctalia/config.toml` | `~/.config/noctalia/config.toml` | `modules/noctalia.nix` |

- Saving the file in `/etc/nixos` applies it; no rebuild or activation is
  needed. Umbriel resolves the symlinks and watches the real file. A rebuild is needed only when the link itself, the helper
  scripts or other Nix code changes.
- Edit the files in the repo, never the `~/.config` links.
- Because `/etc/nixos` is the live copy, edit in your worktree, commit, and
  land it through a PR with `scripts/erebor-land` (parallel-agents skill).
  Landing (the fast-forward of `/etc/nixos`) is when the change goes live, so
  validate before it; a fix found afterwards is a follow-up PR. Rollback is a
  revert PR, not a previous generation.

## Rules

1. Validate before trusting a reload. A config that fails to parse does not
   crash the session: Umbriel keeps the last good config. The edit silently
   does not apply.
   - Noctalia: `noctalia config validate home/noctalia/config.toml`.
2. Confirm it applied: Umbriel's inspection commands (`umbriel submap`,
   `umbriel outputs`, `umbriel windows --json`), or try the behavior.
   Anything visible is done only when a screenshot shows it right. Keep
   screenshots out of the user's folders and delete them afterwards.
3. Keybinding, output, input, idle and portal changes can take down the
   session the user is looking at. Do not experiment with them live; reason
   them out first and have the rollback ready. A bar, notification or theme
   tweak is safe to try and undo.
4. A logout is only needed when a change cannot be applied by the live
   reload.

## Noctalia's settings window

Noctalia's settings window saves to `~/.local/state/noctalia/settings.toml`,
which overrides `config.toml`; it is not in the repo. When the user asks to
sync or save their Noctalia settings into the config, follow
[docs/noctalia-settings.md](../../../docs/noctalia-settings.md).
