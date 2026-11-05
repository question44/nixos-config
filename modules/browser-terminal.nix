{ config, pkgs, ... }:
let
  terminalAssets = pkgs.callPackage ../packages/ttyd-web-assets.nix { };
in
{
  environment.systemPackages = [
    (pkgs.callPackage ../packages/trzsz.nix { })
    pkgs.chafa # inline image previews (chafa -f sixel image.png)
  ];

  services.ttyd = {
    enable = true;
    interface = "127.0.0.1";
    port = 17681;
    user = "janzon";
    writeable = true;
    checkOrigin = true;
    indexFile = "${terminalAssets}/index.html";
    entrypoint = [ "${pkgs.fish}/bin/fish" "--login" ];
    clientOptions = {
      titleFixed = "Erebor terminal";
      fontSize = "16";
      enableTrzsz = "true";
      enableSixel = "true";
      # The page or the embedding dashboard paints the background (see ttyd-web-assets).
      allowTransparency = "true";
      theme = ''{"background":"rgba(43,43,43,0)"}'';
      # ttyd parses a leading quoted family as JSON and drops trailing fallbacks.
      fontFamily = "Erebor Terminal, Erebor Terminal Symbols, monospace";
    };
  };

  systemd.services.ttyd = {
    path = [ config.system.path config.home-manager.users.janzon.home.path ];
    environment = {
      HOME = "/home/janzon";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    serviceConfig = {
      WorkingDirectory = "/home/janzon";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
    };
  };

  services.caddy.extraConfig = ''
    (browser_terminal) {
      @terminal_host host terminal.erebor.jzon.pl
      handle @terminal_host {
        @terminal_tailnet remote_ip 127.0.0.1 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48
        handle @terminal_tailnet {
          route {
            # Share the desktop's runtime password gate, including fail-closed setup.
            import /var/lib/desktop-auth/auth.caddy
            @terminal_bad_origin {
              header Origin *
              not header Origin https://terminal.erebor.jzon.pl
            }
            respond @terminal_bad_origin "Invalid terminal origin." 403
            # The dashboard on erebor.jzon.pl may show the terminal in an in-page window.
            header Content-Security-Policy "frame-ancestors 'self' https://erebor.jzon.pl"
            handle /fonts/* {
              root * ${terminalAssets}
              file_server
            }
            handle {
              reverse_proxy 127.0.0.1:17681 {
                header_up -Authorization
              }
            }
          }
        }
        respond "Terminal access requires Tailscale." 403
      }
    }
  '';
}
