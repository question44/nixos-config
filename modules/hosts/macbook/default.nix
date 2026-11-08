# The MacBook Pro (Tailscale name "macbook"), managed with nix-darwin; see
# docs/mac.md to install and apply it. Evaluated on erebor by
# `nix flake check` (checks.x86_64-linux.eval-darwin-macbook); it can only be
# built and activated on the Mac itself.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) darwin;
in
{
  flake.darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
    modules = [ darwin.macbook ];
  };

  flake.modules.darwin.macbook = {
    imports = [ darwin.base ];

    # Facts checked over SSH on 2026-11-08: macOS 27.0.1 on Apple silicon,
    # user janzon, Homebrew in /opt/homebrew, no Nix yet (install Determinate
    # Nix, see docs/mac.md and nix.enable in modules/darwin/base.nix).
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.primaryUser = "janzon";
    # The Mac's LocalHostName is "Jans-MacBook-Pro". Left unset on purpose:
    # setting networking.hostName makes nix-darwin rewrite HostName,
    # LocalHostName and ComputerName with scutil.

    homebrew = {
      # Installed on 2026-11-08, so nix-darwin knows them; cleanup is "none",
      # so nothing unlisted is removed.
      casks = [
        "discord"
        "ghostty"
        "iina"
        "kde-connect"
        "raycast"
        "remoteviewer"
        "secretive"
        "spice-client"
        "spotify"
        "tailscale-app"
        "temurin@25"
      ];
      # Command-line tools still from Homebrew; docs/mac.md lists the ones that
      # can move to Nix packages.
      brews = [
        "ast-grep"
        "autojump"
        "fd"
        "fish"
        "fisher"
        "fzf"
        "git"
        "imagemagick"
        "iperf3"
        "lazygit"
        "midnight-commander"
        "neovim"
        "ripgrep"
        "sleepwatcher"
        "starship"
        "wget"
        "zsh"
      ];
    };

    # nix-darwin's state version for a first install.
    system.stateVersion = 7;
  };
}
