# Settings every workstation shares: Nix, networking, locale, the main user,
# polkit and desktop plumbing. Host-specific values come from my.* options.
{ config, lib, pkgs, ... }:
let
  user = config.my.user;
  domain = config.my.domain;
  lan = config.my.lanInterface;
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [
      config.networking.hostName
      "torrent" "torrent.localhost"
      "jellyfin" "jellyfin.localhost"
      "nextcloud" "nextcloud.localhost"
      "syncthing" "syncthing.localhost"
    ];
  };
  # SSH is reachable from the LAN and the tailnet only.
  networking.firewall.interfaces.${lan} = {
    allowedTCPPorts = [ 22 80 8095 8096 8384 8082 22000 ];
    allowedUDPPorts = [ 22000 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 80 443 22000 ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 22000 ];
  services.tailscale.enable = true;
  services.cockpit = {
    enable = true;
    openFirewall = false;
    allowed-origins = [
      "https://sys.${domain}"
      "wss://sys.${domain}"
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
  users.users.${user} = {
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

}
