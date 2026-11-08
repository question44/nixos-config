# Everything an erebor-like desktop shares. Hosts import this aspect, add
# their hardware, and set the my.* options (see modules/my.nix).
{ config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.workstation = {
    imports = with nixos; [
      base
      session
      keyring
      ssh
      caddy
      packages
      my
      ambilight
      mac-approval
      spotify
      sunshine
      remote-desktop
      browser-desktop
      browser-terminal
      steam-theme
      jellyfin
      syncthing
      qbittorrent
      proton-vpn-bridge
      nextcloud
      ollama
      t3code
      cockpit
      timemachine
      desktop
      # Formerly added to every host by flake.nix.
      moonshine
      noctalia
      umbriel
      dashboard-control
      vicinae
      darkly
      niri
      home-manager
      update-branch
      secrets
    ];
  };
}
