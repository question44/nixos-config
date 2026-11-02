{ config, pkgs, ... }:
{
  # The browser endpoint is authenticated by tailnet membership. Neither the
  # RFB backend nor a public/LAN HTTP route exposes the desktop.
  systemd.user.services.browser-desktop = {
    description = "Browser access to the current Umbriel desktop";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [ pkgs.jq ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "browser-desktop" ''
        export UMBRIEL_SOCKET="''${UMBRIEL_SOCKET:-$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock}"
        # The focused output contains the desktop the user is operating.
        output=$(${config.programs.umbriel.package}/bin/umbriel outputs --json | jq -r '.[] | select(.focused and .enabled) | .name')
        test -n "$output"
        exec ${pkgs.wayvnc}/bin/wayvnc -C /dev/null -v -R -r -o "$output" -w 127.0.0.1 15901
      '';
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
    };
  };

  services.caddy.extraConfig = ''
    (browser_desktop) {
      @desktop_path path /desktop /desktop/*
      handle @desktop_path {
        @tailnet remote_ip 127.0.0.1 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48
        handle @tailnet {
          redir /desktop /desktop/ 308
          handle /desktop/websockify {
            @same_origin header_regexp Origin ^https://(erebor|moria)[.]jzon[.]pl$
            handle @same_origin {
              reverse_proxy 127.0.0.1:15901
            }
            respond "Invalid desktop WebSocket origin." 403
          }
          handle_path /desktop/* {
            header Content-Security-Policy "frame-ancestors 'self'"
            root * ${pkgs.novnc}/share/webapps/novnc
            rewrite / /vnc.html
            file_server
          }
        }
        respond "Desktop access requires Tailscale." 403
      }
    }
  '';
}
