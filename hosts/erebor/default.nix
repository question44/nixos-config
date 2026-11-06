{ lib, pkgs, ... }:

{
  imports = [
    # Split from this file; listed first to keep its original merge order.
    ./boot.nix
    ./storage.nix
    ./input.nix
    ./session.nix
    ./t3code.nix
    ./keyring.nix
    ./ssh.nix
    ./caddy.nix
    ./packages.nix
    ../../modules/my.nix
    ../../modules/ambilight.nix
    ../../modules/mac-approval.nix
    ../../modules/spotify.nix
    ../../modules/sunshine.nix
    ../../modules/remote-desktop.nix
    ../../modules/browser-desktop.nix
    ../../modules/browser-terminal.nix
    ../../modules/steam-theme.nix
    ./hardware-configuration.nix
    ./services/jellyfin.nix
    ./services/syncthing.nix
    ./services/qbittorrent.nix
    ./services/nextcloud.nix
    ./services/ollama.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
    ../../modules/windows-vm.nix
    ../../modules/looking-glass.nix
  ];

  my = {
    user = "janzon";
    domain = "erebor.jzon.pl";
    ambilight.enable = true;
    wledUrl = "http://192.168.1.118";
    yubikey.enable = true;
    macApproval.enable = true;
    nanokvm = {
      enable = true;
      url = "https://kvm-37ff.tail517bdc.ts.net:8443";
    };
  };

  # Shut down windows11 before toggling GPU ownership.
  virtualisation.windowsGpuPassthrough.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.hostName = "erebor";
  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [
      "erebor"
      "torrent" "torrent.localhost"
      "jellyfin" "jellyfin.localhost"
      "nextcloud" "nextcloud.localhost"
      "syncthing" "syncthing.localhost"
    ];
  };
  # SSH is reachable from the LAN and the tailnet only.
  networking.firewall.interfaces.br0.allowedTCPPorts = [ 22 80 8095 8096 8384 8082 22000 ];
  networking.firewall.interfaces.br0.allowedUDPPorts = [ 22000 ];
  networking.firewall.interfaces.br0.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.interfaces.br0.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 80 443 22000 ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 22000 ];
  services.tailscale.enable = true;
  services.cockpit = {
    enable = true;
    openFirewall = false;
    allowed-origins = [
      "https://sys.erebor.jzon.pl"
      "wss://sys.erebor.jzon.pl"
    ];
    settings.WebService = {
      AllowUnencrypted = true;
      LoginTo = false;
      ProtocolHeader = "X-Forwarded-Proto";
    };
  };
  hardware.i2c.enable = true;
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl";

  users.defaultUserShell = pkgs.fish;
  users.users.janzon = {
    isNormalUser = true;
    description = "Janzon";
    shell = pkgs.fish;
    linger = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
  };

  programs.fish.enable = true;
  programs.steam.enable = true;
  programs.nix-ld.enable = true;

  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel") &&
          [
            "org.freedesktop.login1.reboot",
            "org.freedesktop.login1.reboot-multiple-sessions",
            "org.freedesktop.login1.power-off",
            "org.freedesktop.login1.power-off-multiple-sessions",
            "org.freedesktop.login1.suspend",
            "org.freedesktop.login1.suspend-multiple-sessions"
          ].indexOf(action.id) >= 0) {
        return polkit.Result.YES;
      }
    });
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel") &&
          action.id == "org.freedesktop.udisks2.filesystem-mount-system") {
        return polkit.Result.YES;
      }
    });
  '';

  services.dbus.enable = true;

  services.udisks2.enable = true;
  # SMART disk health monitoring; warnings go to logged-in terminals (wall).
  services.smartd.enable = true;

  programs.dconf.enable = true;

  services.xserver.enable = false;

  system.stateVersion = "26.05";
}
