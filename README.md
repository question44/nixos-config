# erebor NixOS configuration

The flake-based NixOS configuration for the desktop `erebor`, together with
Home Manager configuration for the `janzon` user. This file is the human
overview. Rules for maintaining the system (and for AI agents working on it)
are in [AGENTS.md](AGENTS.md).

## Layout

| Path | Contents |
|---|---|
| `flake.nix` | Inputs (nixpkgs 26.05, Home Manager, Umbriel, Noctalia, browsers, flake-parts, import-tree, …). Its outputs are every file under `modules/`, loaded with import-tree. |
| `modules/` | The dendritic module tree. Every `.nix` file is a flake-parts module that adds NixOS and/or Home Manager *aspects* to `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>`; flake inputs reach them by closure (`{ inputs, ... }:`), not `specialArgs`. A feature that spans both (Umbriel, Noctalia, Vicinae, Darkly, xremap, Spotify, Steam theme) keeps both halves in one file. Paths with a `_`-prefixed component are not loaded. |
| `modules/flake/` | flake-parts setup (`systems`, the `flake.modules` option) and `nix fmt` / the format check. |
| `modules/hosts/erebor/` | This machine: `default.nix` builds `nixosConfigurations.erebor` from aspects and sets its `my.*` values; `boot.nix`, `storage.nix` and `_hardware-configuration.nix` hold the rest. |
| `modules/hosts/template/` | A starting point for a new machine. It is built as `nixosConfigurations.template` but never deployed, which proves the optional features can be switched off. |
| `modules/my.nix` | Declares the per-machine `my.*` options (see below). |
| `modules/workstation/` | The shared desktop profile: base system, session, keyring, SSH, Caddy, packages, and the `workstation` aspect that imports every shared feature aspect. |
| `modules/services/` | Web services (Jellyfin, Nextcloud, Syncthing, qBittorrent, Ollama, t3code, Cockpit), each registered in `my.services`. |
| `modules/*.nix` | Feature aspects: ambilight, Mac approval, Sunshine/Moonshine, Umbriel, Noctalia, NVIDIA, Windows VM, Looking Glass, xremap, … Hardware-specific ones are imported per host. |
| `modules/home/` | Home Manager: `janzon.nix` (the Home Manager integration and janzon's profile, which lists the `homeManager` aspects) and the topic aspects `apps`, `desktop` and `shell`. |
| `home/<app>/` | Dotfiles that Home Manager deploys (Umbriel, Noctalia, fish, Ghostty, nvim, xremap, …). Edit them here, never the deployed copies in `~/.config`. |
| `packages/` | Custom package builds. |
| `apps/erebor-dashboard/` | The dashboard, a Git submodule with its own [README](apps/erebor-dashboard/README.md). |
| `scripts/` | Helpers for rebuilding, worktrees and system diffs (see below). |
| `Makefile` | Maintenance tasks. Run `make help` to list them. |

## The `my.*` options

Shared modules read `config.my.*` instead of hard-coding the user, domain,
addresses or devices. A host sets these values in `modules/hosts/<name>/default.nix`.
Every option, with its type, default and description, is listed in
[docs/my-options.md](docs/my-options.md), generated from the declarations
(`nix run .#write-docs` after changing one; `nix flake check` fails while the
file is stale).

`virtualisation.windowsGpuPassthrough.enable` passes the RTX 4090 to the
`windows11` VM instead of the host (`modules/windows-vm.nix`). Shut the VM down
before toggling. See [docs/windows-vm.md](docs/windows-vm.md).

Upstream options (anything from NixOS or Home Manager) work as usual. Search
them on [search.nixos.org](https://search.nixos.org/options) or in the
[Home Manager options](https://home-manager-options.extranix.com/).

### Adding a web service

1. Create `modules/services/<name>.nix`. Register the service unconditionally
   under `my.services.<name>` (port, names, LAN port), then put the actual
   service under `lib.mkIf config.my.services.<name>.enable`.
   `modules/services/jellyfin.nix` is a short example.
2. Define it as `flake.modules.nixos.<name>` and add `<name>` to the
   `workstation` aspect's imports in `modules/workstation/default.nix`.
3. Set `my.services.<name>.enable = true;` in the host.

## Building and activating

```bash
nix flake check                         # evaluation, plus the nixfmt check
scripts/erebor-rebuild build            # build without activating (any checkout)
scripts/erebor-rebuild test             # activate until reboot (/etc/nixos on master only)
scripts/erebor-rebuild switch           # activate and make it the boot default
```

`erebor-rebuild` holds a lock so only one rebuild runs at a time, uses the
setuid `sudo` (YubiKey or Mac approval), and refuses to activate any checkout
other than `/etc/nixos` on `master`. Activating another tree would roll back
whatever is on `master` but missing from it.

Other helpers:

- `scripts/erebor-worktree <task>` creates `~/nixos-wt/<task>` on branch
  `agent/<task>`, so parallel changes don't collide.
- `scripts/erebor-diff` reports whether a checkout changes the built system
  compared with `master`: identical (same derivation), equivalent (every
  rebuilt store path matches its counterpart once store hashes are masked),
  or different (with diffs of what changed).
- `nix fmt` formats every `.nix` file outside `apps/`. Run it before
  committing; `nix flake check` fails on unformatted files.

## Records

| File | Contents |
|---|---|
| [SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md) | Dated changes for the current month, with verification. Older months are in `changelog/`. |
| [tasks/](tasks/README.md) | Unfinished work, one `SYS-NNN` file per task; `scripts/erebor-tasks` shows the board. |
| [SYSTEM_CONTEXT.md](SYSTEM_CONTEXT.md) | State that isn't declared in Nix: manual setup, recovery paths, verified pitfalls. |
| [docs/windows-vm.md](docs/windows-vm.md) | Windows 11 VM, GPU passthrough and Looking Glass. |
| [docs/mac-approval.md](docs/mac-approval.md) | How sudo is approved from the MacBook. |
| [docs/noctalia-settings.md](docs/noctalia-settings.md) | Moving settings made in Noctalia's settings window into the flake. |
