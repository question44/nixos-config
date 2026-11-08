# The Mac under nix-darwin

`darwinConfigurations.macbook` (`modules/hosts/macbook/default.nix`) manages
the MacBook Pro with nix-darwin: system defaults, Touch ID for `sudo`, a
Nerd Font, the Homebrew apps, and Home Manager with the aspects shared with
erebor (`modules/darwin/base.nix`). On erebor, `nix flake check` only
evaluates it (`eval-darwin-macbook`); it is built and applied on the Mac.

## What it changes on first apply

- Dock autohide on (it is off today); Finder shows extensions and the path
  bar; fast key repeat with press-and-hold accents off; tap to click.
- `/etc/pam.d/sudo_local` with `pam_tid.so`: Touch ID for `sudo` (new).
- Homebrew: the casks and formulae installed on 2026-11-08 are declared.
  `onActivation.cleanup = "none"`, so nothing unlisted is removed, and
  nothing is upgraded or auto-updated during activation.
- Home Manager (backups get the `.backup` suffix):
  - `~/.config/nvim` becomes a link to `home/nvim`, erebor's LazyVim config.
    The existing directory moves to `~/.config/nvim.backup`. Its
    `lazyvim.json` (no extras), `stylua.toml` and `.neoconf.json` are not
    carried over; `lazy-lock.json` now lives in Neovim's state directory.
    Neovim itself stays from Homebrew.
  - `~/.config/fish/config.fish` is generated: the shared aliases and the
    `imgs` function from `modules/home/shell.nix`, Starship's init, and
    `SSH_AUTH_SOCK` for Secretive. The old file moves to
    `config.fish.backup`. Fisher keeps `functions/`, `completions/`,
    `conf.d/` and `fish_plugins`, so nvm.fish keeps working. The login shell
    stays Homebrew's fish.
  - `~/.config/starship.toml` is `home/starship-mac.toml`, the current
    powerline prompt with its fixed colours.
  - `~/.config/ghostty/config.ghostty` is `home/ghostty/config-macos.ghostty`
    (a fixed theme, since Noctalia's theme exists only on erebor).
  - `eza` and `chafa` from Nix, for the shared `ls`/`img` aliases; Home
    Manager also installs Nix's `fish`, `starship` and `bat`.
- The hostname is left alone (`networking.hostName` is not set).

## Install

1. Install Determinate Nix (the config sets `nix.enable = false` for it):

   ```bash
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   ```

   With the official installer instead, remove `nix.enable = false` from
   `modules/darwin/base.nix`.

2. First activation, from GitHub (the branch with this config) or a clone:

   ```bash
   sudo nix run nix-darwin -- switch --flake github:question44/nixos-config/<branch>#macbook
   # or, in a clone:
   sudo nix run nix-darwin -- switch --flake .#macbook
   ```

   The repository uses a git submodule (the erebor dashboard); a plain
   `git clone` without `--recurse-submodules` still evaluates the Mac, since
   only erebor uses it.

3. Afterwards: `sudo darwin-rebuild switch --flake .#macbook`. Check
   `sudo -k; sudo true` asks for Touch ID, the Dock hides, and a new fish
   shell shows the usual prompt and `ssh-add -l` lists Secretive's keys.

Rollback: `sudo darwin-rebuild --rollback`, or restore a `*.backup` file.

## Later steps

- Formulae that can move to Nix packages (`home.packages` in the darwin
  part of `modules/home/shell.nix`, then remove them from `brews`): `fd`,
  `fzf`, `ripgrep`, `lazygit`, `neovim`, `starship`, `ast-grep`, `git`,
  `wget`, `iperf3`, `imagemagick`, `midnight-commander`.
- Keep `fish`, `fisher`, `autojump`, `zsh` and `sleepwatcher` in Homebrew
  until the shell itself is managed by Home Manager. Moving to Nix's fish:
  `programs.fish.enable = true` in nix-darwin, `users.users.janzon.shell =
  pkgs.fish` (and `users.knownUsers` for nix-darwin to change it), then drop
  the Homebrew fish.
- Zed is not managed on the Mac yet (on erebor it is a Noctalia template).
- KDE Connect stays a cask; its pairing state is per-machine identity and
  stays out of Nix.
- Once the Homebrew lists are complete, `cleanup = "uninstall"` makes them
  authoritative; check `brew bundle cleanup` first.
