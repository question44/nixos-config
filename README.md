# erebor NixOS configuration

The flake-based NixOS configuration for the desktop `erebor`, together with
Home Manager configuration for the `janzon` user. This file is the human
overview. Rules for maintaining the system (and for AI agents working on it)
are in [AGENTS.md](AGENTS.md).

## Layout

| Path | Contents |
|---|---|
| `flake.nix` | Inputs (nixpkgs 26.05, Home Manager, Umbriel, Noctalia, Niri helpers, browsers, …) and the `mkHost` function that builds each host. |
| `hosts/erebor/` | Settings specific to this machine: hardware, boot, storage, and its `my.*` values in `default.nix`. |
| `hosts/template/` | A starting point for a new machine. It is built as `nixosConfigurations.template` but never deployed, which proves the optional features can be switched off. |
| `modules/my.nix` | Declares the per-machine `my.*` options (see below). |
| `modules/workstation/` | The shared desktop profile: base system, session, keyring, SSH, Caddy, packages, and imports of the feature modules. |
| `modules/services/` | Web services (Jellyfin, Nextcloud, Syncthing, qBittorrent, Ollama, t3code, Cockpit), each registered in `my.services`. |
| `modules/*.nix` | Feature modules: ambilight, Mac approval, Sunshine/Moonshine, NVIDIA, Windows VM, Looking Glass, xremap, … Hardware-specific ones are imported per host. |
| `home/janzon/` | Home Manager entry point, split into `apps`, `compositor`, `desktop` and `shell`. |
| `home/<app>/` | Dotfiles that Home Manager deploys (Umbriel, Niri, Noctalia, fish, Ghostty, nvim, xremap, …). Edit them here, never the deployed copies in `~/.config`. |
| `packages/` | Custom package builds. |
| `apps/erebor-dashboard/` | The dashboard, a Git submodule with its own [README](apps/erebor-dashboard/README.md). |
| `scripts/` | Helpers for rebuilding, worktrees and system diffs (see below). |
| `Makefile` | Maintenance tasks. Run `make help` to list them. |

## The `my.*` options

Shared modules read `config.my.*` instead of hard-coding the user, domain,
addresses or devices. A host sets these values in `hosts/<name>/default.nix`.
The full declarations, with descriptions, are in
[modules/my.nix](modules/my.nix).

| Option | Purpose |
|---|---|
| `my.user.name`, `my.user.description` | Login name and full name of the main user. |
| `my.network.domain` | Public domain. Services are served on its subdomains. |
| `my.network.lanInterface` | LAN interface whose firewall allows local services (e.g. `br0`). |
| `my.services.<name>.enable` | Turns on a web service from `modules/services/`. Its Caddy routes, `/etc/hosts` names and LAN firewall port are generated from the registry (`port`, `localName`, `publicName`, `lanPort`, `proxy.*`, `extraConfig`). |
| `my.niri.enable` | Niri as a second compositor next to Umbriel. |
| `my.streaming.sunshine.enable` | The Sunshine game-streaming setup. |
| `my.streaming.moonshine.enable` | The Moonshine game-streaming server. |
| `my.ambilight.{enable, musicSink, wledUrl}` | HyperHDR ambient lighting, the PipeWire sink it captures for music effects, and the WLED controller. |
| `my.yubikey.{enable, sound}` | YubiKey touch for sudo, and the sound played while it waits. |
| `my.macApproval.{enable, addresses}` | Approving sudo and polkit through a forwarded Mac SSH agent. See [MAC_APPROVAL.md](MAC_APPROVAL.md). |
| `my.nanokvm.{enable, url}` | NanoKVM wake and outlet readings in the dashboard. |
| `my.xremap.devices` | Input devices that xremap remaps, given by name and optionally USB IDs (`modules/xremap.nix`). |
| `virtualisation.windowsGpuPassthrough.enable` | Passes the RTX 4090 to the `windows11` VM instead of the host (`modules/windows-vm.nix`). Shut the VM down before toggling. See [WINDOWS_VM.md](WINDOWS_VM.md). |

Upstream options (anything from NixOS or Home Manager) work as usual. Search
them on [search.nixos.org](https://search.nixos.org/options) or in the
[Home Manager options](https://home-manager-options.extranix.com/).

### Adding a web service

1. Create `modules/services/<name>.nix`. Register the service unconditionally
   under `my.services.<name>` (port, names, LAN port), then put the actual
   service under `lib.mkIf config.my.services.<name>.enable`.
   `modules/services/jellyfin.nix` is a short example.
2. Import it in `modules/workstation/default.nix`.
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
  compared with `master`: identical, equivalent, or different.
- `nix fmt` formats every `.nix` file outside `apps/`. Run it before
  committing; `nix flake check` fails on unformatted files.

## Records

| File | Contents |
|---|---|
| [SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md) | Dated changes for the current month, with verification. Older months are in `changelog/`. |
| [SYSTEM_TODO.md](SYSTEM_TODO.md) | Unfinished work, as `SYS-NNN` tasks. |
| [SYSTEM_CONTEXT.md](SYSTEM_CONTEXT.md) | State that isn't declared in Nix: manual setup, recovery paths, verified pitfalls. |
| [WINDOWS_VM.md](WINDOWS_VM.md) | Windows 11 VM, GPU passthrough and Looking Glass. |
| [MAC_APPROVAL.md](MAC_APPROVAL.md) | How sudo is approved from the MacBook. |
