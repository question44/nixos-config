# Graphical session: greeter, compositors, Noctalia, portals, audio and Helium.
{ config, lib, pkgs, ... }:
let
  user = config.my.user;
  noctaliaPython = pkgs.callPackage ../../packages/noctalia-python.nix { };
in
{
  systemd.user.services.noctalia-lyrics = {
    description = "Noctalia Spotify lyrics daemon";
    after = [ "graphical-session.target" "noctalia.service" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.playerctl ];
    serviceConfig = {
      ExecStart = "${noctaliaPython}/bin/python3 -B /home/${user}/.local/state/noctalia/plugins/materialized/community/spotify-lyrics/spotify_lyrics_daemon.py";
      Restart = "on-failure";
      RestartSec = 5;
    };
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

  systemd.user.services.xdg-desktop-portal = {
    after = [ "graphical-session.target" "xdg-desktop-portal-gnome.service" ];
    wants = [ "xdg-desktop-portal-gnome.service" ];
    # The host app registry resolves desktop-file Exec= commands via PATH;
    # without the system/user profiles it rejects apps like vicinae.
    path = [ "/run/current-system/sw" "/etc/profiles/per-user/${user}" ];
  };

  # A graphical greeter does not need Type=idle's console-output delay.
  systemd.services.greetd.serviceConfig.Type = lib.mkForce "exec";

  services.displayManager.noctalia-greeter = {
    enable = true;
    passwordless-sync-users = [ "${user}" ];
    settings = {
      appearance.scheme = "Synced";
      user.default = "${user}";
      session.default = "umbriel";
      idle.timeout = 60;
    };
  };

  systemd.user.services.niri.enableDefaultPath = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.client."90-hyperhdr-music" = lib.mkIf config.my.ambilight.enable {
      "stream.rules" = [
        {
          matches = [
            {
              "application.process.binary" = ".hyperhdr-wrapped";
              "media.class" = "Stream/Input/Audio";
            }
          ];
          actions.update-props = {
            "target.object" = "alsa_output.usb-iFi__by_AMR__iFi__by_AMR__HD_USB_Audio_0003-00.analog-stereo";
            "stream.capture.sink" = true;
          };
        }
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.oo7-portal pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
    configPackages = [ pkgs.niri ];
    config.niri = {
      "org.freedesktop.impl.portal.Secret" = lib.mkForce "oo7";
      "org.freedesktop.impl.portal.ScreenCast" = "gnome";
    };
  };

  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  programs.umbriel.enable = true;

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    recommendedServices.enable = true;
  };

  # Noctalia updates this policy with the current palette for Helium.
  # Preserve the rendered color across rebuilds; this must stay a writable file.
  systemd.tmpfiles.settings."10-noctalia-chromium".
    "/etc/chromium/policies/managed/noctalia-color.json".f = {
      user = "${user}";
      group = "users";
      mode = "0644";
      argument = "{}";
    };

  programs.helium = {
    enable = true;
    flags = [ "--password-store=gnome-libsecret" ];
  };
}
