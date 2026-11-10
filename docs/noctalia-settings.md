# Syncing Noctalia settings into the flake

Noctalia reads `~/.config/noctalia/config.toml`, which Home Manager links
to `/etc/nixos/home/noctalia/config.toml` (live: a merged edit applies
without activation). Changes made in Noctalia's settings window
are saved to `~/.local/state/noctalia/settings.toml`, which overrides it. Over
time the repo copy falls behind what is on screen, and the overrides hide any
later edit to the Nix file.

To sync, fold the overrides into `home/noctalia/config.toml`, merge it, then
trim `settings.toml` back to what belongs outside Git. The effective
configuration must not change. Follow the worktree, build and activation rules
in [AGENTS.md](../AGENTS.md).

## What stays out of the repo

Keep these in `settings.toml` only:

- `plugin_settings."noctalia/wallhaven".api_key`, and any other key, token or
  password.
- `[wallpaper.last]` and `[[wallpaper.favorite]]`, which are history rather
  than settings. `noctalia config export` does not print them, so they are
  easy to lose.
- `auto_hide`, `smart_auto_hide` and `reserve_space` under `[bar.default]`:
  the bar's pin button (`noctalia-bar-autohide`) writes them there as its
  persistent mode.

Plugin code stays out too. Noctalia downloads plugins from the
`[[plugins.source]]` entries; only the enabled list and `plugin_settings`
belong in the config.

## Steps

1. Check that there is something to sync. If `settings.toml` holds only the
   keys listed above, stop.

2. Create a worktree: `scripts/erebor-worktree noctalia-sync`.

3. Export the merged config. Noctalia loads every `*.toml` in its config
   directory, including the Starship files there, so export from a temporary
   directory that holds only `config.toml`:

   ```bash
   t=$(mktemp -d); mkdir -p "$t/noctalia"
   cp -L ~/.config/noctalia/config.toml "$t/noctalia/"
   XDG_CONFIG_HOME=$t noctalia config export > merged.toml
   ```

   Use the deployed `config.toml`, not the worktree copy, so the export
   matches what is running.

4. Clean up `merged.toml`, then write it to `home/noctalia/config.toml`:
   - Remove everything listed in "What stays out of the repo".
   - Round floats to the shortest decimal that keeps the setting
     (`0.53999998793005943` → `0.54`).
   - Drop values equal to Noctalia's built-in defaults. Get the defaults with
     an empty config and state:
     `XDG_CONFIG_HOME=$(mktemp -d) XDG_STATE_HOME=$(mktemp -d) noctalia config export full`.
     Keep `lockscreen_widgets.schema_version`.
   - Drop `[widget.<id>]` blocks, including their subtables, for widget IDs
     not used by any bar, capsule group, lockscreen or control-center layout.
   - Keep the comments from the previous `home/noctalia/config.toml` above the
     same tables.
   - Run `noctalia config validate home/noctalia/config.toml`. Fix any
     warnings, for example a widget whose plugin has been removed.

5. Check that only the cleanup changed the config. Build two temporary config
   and state pairs:
   - before: the deployed `config.toml` with the current `settings.toml`;
   - after: the new `config.toml` with a `settings.toml` trimmed as in step 8,
     in a temporary state directory.

   Run `noctalia config export full` against each, and diff. The diff may show
   only rounding below 1e-6 and the removed widget blocks. Show the user the
   `git diff` of `home/noctalia/config.toml` and ask before going on.

6. Add a `SYSTEM_CHANGELOG.md` entry, run `nix fmt`, `nix flake check` and
   `scripts/erebor-rebuild build`, commit and land it with
   `scripts/erebor-land`. The config is linked live from `/etc/nixos`, so
   landing applies it; no activation is needed unless the change also touched
   Nix code.

7. Only after the merged config is live, back up the overrides:
   `cp -p ~/.local/state/noctalia/settings.toml ~/.local/state/noctalia/settings.toml.bak-<date>`.
   Trimming before landing drops the user's changes from the live desktop
   until the new config is in `/etc/nixos`.

8. Rewrite `settings.toml` to `config_version = <current version>` plus the
   keys from "What stays out of the repo", copied from the backup. Do not
   print the API key. Run `noctalia msg config-reload`.

9. Verify: compare `noctalia config export full` against the one taken before
   step 7, check `journalctl --user -u noctalia` for new warnings and
   `systemctl --user --failed`, then record the generation and result in the
   changelog entry and commit.
