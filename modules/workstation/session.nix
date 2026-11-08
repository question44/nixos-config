# Graphical session plumbing: portals, audio and Helium. The greeter,
# compositors and shell live in their own aspects (noctalia, umbriel, niri).
{ inputs, ... }:
{
  flake.modules.nixos.session =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
    in
    {
      imports = [ inputs.helium.nixosModules.default ];

      systemd.user.services.xdg-desktop-portal = {
        after = [
          "graphical-session.target"
          "xdg-desktop-portal-gnome.service"
        ];
        wants = [ "xdg-desktop-portal-gnome.service" ];
        # The host app registry resolves desktop-file Exec= commands via PATH;
        # without the system/user profiles it rejects apps like vicinae.
        path = [
          "/run/current-system/sw"
          "/etc/profiles/per-user/${user}"
        ];
      };

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
                "target.object" = config.my.ambilight.musicSink;
                "stream.capture.sink" = true;
              };
            }
          ];
        };
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.oo7-portal
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
        ];
      };

      programs.helium = {
        enable = true;
        flags = [ "--password-store=gnome-libsecret" ];
      };
    };
}
