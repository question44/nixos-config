# Niri as a second compositor next to Umbriel (my.niri.enable): the session,
# its overview wallpaper, and home/niri's config and helper scripts.
{
  flake.modules.nixos.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
    in
    lib.mkIf config.my.niri.enable {
      environment.etc."xdg/niri/config.kdl".source = ../home/niri/config.kdl;

      programs.niri = {
        enable = true;
        useNautilus = false;
      };
      systemd.user.services.niri-overview-wallpaper = {
        description = "Niri overview backdrop wallpaper";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -o DP-1 -i /home/${user}/Pictures/wallhaven-vpeq6l.jpg -m fill";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
      systemd.user.services.niri.enableDefaultPath = false;
      xdg.portal = {
        configPackages = [ pkgs.niri ];
        config.niri = {
          "org.freedesktop.impl.portal.Secret" = lib.mkForce "oo7";
          "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        };
      };
    };

  flake.modules.homeManager.niri =
    { lib, osConfig, ... }:
    lib.mkIf osConfig.my.niri.enable {
      xdg.configFile."systemd/user/niri-overview-wallpaper.service.d/override.conf".source =
        ../home/systemd/niri-overview-wallpaper-override.conf;
      xdg.configFile."niri/config.kdl".source = ../home/niri/config.kdl;
      home.file.".local/bin/niri-overview-wallpaper" = {
        source = ../home/dolphin/niri-overview-wallpaper;
        executable = true;
      };
      home.file.".local/bin/niri-caps-q" = {
        source = ../home/niri/caps-q-window;
        executable = true;
      };
      home.file.".local/bin/niri-focus-or-launch" = {
        source = ../home/niri/focus-or-launch;
        executable = true;
      };
      home.file.".local/bin/niri-background-apps-last" = {
        source = ../home/niri/background-apps-last;
        executable = true;
      };
      home.file.".local/bin/niri-caps-q-quit" = {
        source = ../home/niri/caps-q-quit;
        executable = true;
      };
      home.file.".local/share/kio/servicemenus/set-niri-overview-wallpaper.desktop" = {
        source = ../home/dolphin/set-niri-overview-wallpaper.desktop;
        executable = true;
      };
    };
}
