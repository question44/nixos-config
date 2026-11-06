# Everything an erebor-like desktop shares. Hosts import this, add their
# hardware, and set the my.* options (see modules/my.nix).
{
  imports = [
    ./base.nix
    ./session.nix
    ./keyring.nix
    ./ssh.nix
    ./caddy.nix
    ./packages.nix
    ../my.nix
    ../ambilight.nix
    ../mac-approval.nix
    ../spotify.nix
    ../sunshine.nix
    ../remote-desktop.nix
    ../browser-desktop.nix
    ../browser-terminal.nix
    ../steam-theme.nix
    ../services/jellyfin.nix
    ../services/syncthing.nix
    ../services/qbittorrent.nix
    ../proton-vpn-bridge.nix
    ../services/nextcloud.nix
    ../services/ollama.nix
    ../services/t3code.nix
    ../services/cockpit.nix
    ../desktop.nix
  ];
}
