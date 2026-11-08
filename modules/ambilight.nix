# HyperHDR ambient lighting through PipeWire screen capture.
{
  flake.modules.nixos.ambilight =
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
      # HyperHDR does not save the LED output state and its WLED driver powers
      # the strip on at startup. The dashboard's "ambilight-off" leaves WLED with
      # lor=2, so reapply "off" after every HyperHDR start while that flag is set.
      hyperhdrRestoreOff = pkgs.writeShellScript "hyperhdr-restore-off" ''
        curl=${pkgs.curl}/bin/curl
        wled=${lib.escapeShellArg config.my.ambilight.wledUrl}
        lor=$($curl -sf -m 3 "$wled/json/state" | ${pkgs.jq}/bin/jq -r .lor) || exit 0
        [ "$lor" = 0 ] && exit 0
        api=http://127.0.0.1:8090/json-rpc
        for _ in $(seq 30); do
          $curl -sf -m 2 -X POST "$api" -d '{"command":"serverinfo","tan":1}' >/dev/null && break
          sleep 1
        done
        $curl -sf -m 5 -X POST "$api" \
          -d '{"command":"componentstate","componentstate":{"component":"LEDDEVICE","state":false},"tan":1}' >/dev/null
        sleep 1
        $curl -sf -m 3 -X POST -H 'Content-Type: application/json' "$wled/json/state" \
          -d '{"on":false,"live":false,"lor":2}' >/dev/null
        echo "Ambilight was off (WLED lor=$lor); kept HyperHDR LEDs and WLED off"
        exit 0
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
            ExecStartPost = lib.mkIf (config.my.ambilight.wledUrl != null) hyperhdrRestoreOff;
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
    };
}
