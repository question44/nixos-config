# HyperHDR ambient lighting through PipeWire screen capture.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyperhdr = pkgs.callPackage ../packages/hyperhdr.nix { };
  hyperhdrPortalCheck = pkgs.writeShellScript "hyperhdr-portal-check" ''
    if ${pkgs.systemd}/bin/busctl --user get-property \
      org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
      org.freedesktop.portal.ScreenCast version 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -Eq '^u [1-9][0-9]*$'; then
      exit 0
    fi

    echo "ScreenCast portal unavailable; restarting portal services before retrying HyperHDR" >&2
    ${pkgs.systemd}/bin/systemctl --user --no-block restart \
      xdg-desktop-portal-gnome.service xdg-desktop-portal.service
    exit 1
  '';
in
{
  config = lib.mkIf config.my.ambilight.enable {
    systemd.user.services.hyperhdr = {
      description = "HyperHDR ambient lighting with PipeWire screen capture";
      after = [
        "graphical-session.target"
        "pipewire.service"
        "wireplumber.service"
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gnome.service"
      ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      wants = [
        "pipewire.service"
        "wireplumber.service"
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gnome.service"
      ];
      serviceConfig = {
        ExecStartPre = hyperhdrPortalCheck;
        ExecStart = "${hyperhdr}/bin/hyperhdr --pipewire --desktop";
        TimeoutStopSec = 5;
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
      };
    };
  };
}
