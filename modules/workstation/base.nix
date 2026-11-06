# Settings every workstation shares: Nix, networking, locale, the main user,
# polkit and desktop plumbing. Host-specific values come from my.* options.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.my.user.name;
  lan = config.my.network.lanInterface;
  services = lib.filter (s: s.enable) (lib.attrValues config.my.services);
  localNames = lib.concatMap (s: [
    s.localName
    "${s.localName}.localhost"
  ]) (lib.filter (s: s.localName != null) services);
  lanPorts = lib.concatMap (s: lib.optional (s.lanPort != null) s.lanPort) services;
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
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
    ]
    ++ localNames;
  };
  # SSH is reachable from the LAN and the tailnet only.
  networking.firewall.interfaces.${lan} = {
    allowedTCPPorts = [
      22
      80
    ]
    ++ lanPorts
    ++ [ 22000 ];
    allowedUDPPorts = [ 22000 ];
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    22
    80
    443
    22000
  ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 22000 ];
  services.tailscale.enable = true;
  hardware.i2c.enable = true;
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl";

  users.defaultUserShell = pkgs.fish;
  users.users.${user} = {
    isNormalUser = true;
    description = config.my.user.description;
    shell = pkgs.fish;
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ];
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
