---
name: desktop-config
description: Use when changing what the desktop shows or does - Umbriel keybinds, layout, outputs or window rules, Noctalia bar/widgets/theme, Niri config, or syncing Noctalia's settings-window changes into the repo.
---

# Changing the desktop (Umbriel, Noctalia, Niri)

Umbriel is the primary compositor session (`XDG_CURRENT_DESKTOP=umbriel`).
Niri is still configured but is not the main session. Desktop and keybind
changes normally belong in Umbriel.

## The live layer

These files are linked live: Home Manager points `~/.config/…` at the file in
`my.flakePath` (`/etc/nixos`) with an out-of-store symlink.

| File in the repo | Linked as | Module |
|---|---|---|
| `home/umbriel/config.toml` | `~/.config/umbriel/config.toml` | `modules/umbriel.nix` |
| `home/noctalia/config.toml` | `~/.config/noctalia/config.toml` | `modules/noctalia.nix` |
| `home/niri/config.kdl` | `~/.config/niri/config.kdl` | `modules/niri.nix` |

- Saving the file in `/etc/nixos` applies it; no rebuild or activation is
  needed. Umbriel resolves the symlinks and watches the real file; Niri
  reloads on save. A rebuild is needed only when the link itself, the helper
  scripts or other Nix code changes.
- Edit the files in the repo, never the `~/.config` links.
- Because `/etc/nixos` is the live copy, edit in your worktree, commit, and
  merge into `master` (parallel-agents skill). The merge is when the change
  goes live. Rollback is git (revert, or check out the previous version), not
  a previous generation.
- `/etc/xdg/niri/config.kdl` is a store copy kept as a fallback.

## Rules

1. Validate before trusting a reload. A config that fails to parse does not
   crash the session: Umbriel and Niri keep the last good config (Niri shows
   "Failed to parse the config file"). The edit silently does not apply.
   - Niri: `niri validate -c home/niri/config.kdl` before merging, then
     `niri msg action load-config-file`.
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
