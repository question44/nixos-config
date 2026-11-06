# Caddy reverse proxy for local names and *.erebor.jzon.pl.
{ config, lib, pkgs, ... }:
let
  domain = config.my.domain;
  dashboard = config.services.erebor-dashboard.package;
  # Spliced into the indented Caddyfile below; the text keeps its layout.
  hyperhdrRoute = hosts: lib.optionalString config.my.ambilight.enable
    "@hyperhdr host ${hosts}\n  handle @hyperhdr {\n    reverse_proxy 127.0.0.1:8090\n  }\n";
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/ovh@v1.1.0" ];
      hash = "sha256-Yakgn5FnLaZqfHzX0cxG/1Ypg/dyKS+n8OPFlIPpdBo=";
    };
    environmentFile = "/etc/caddy/ovh.env";
    globalConfig = "auto_https disable_redirects";
    extraConfig = ''
      (dashboard_controls) {
        handle /api/control* {
          @trusted remote_ip private_ranges 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @trusted {
            reverse_proxy 127.0.0.1:18090
          }
          respond "Controls are available on the local network and tailnet only." 403
        }
      }

      (ovh_tls) {
        tls {
          dns ovh {
            endpoint {$OVH_ENDPOINT}
            application_key {$OVH_APPLICATION_KEY}
            application_secret {$OVH_APPLICATION_SECRET}
            consumer_key {$OVH_CONSUMER_KEY}
          }
          resolvers 1.1.1.1 9.9.9.9
        }
      }

      :80 {
        @domain host ${domain} *.${domain}
        redir @domain https://{host}{uri} permanent

        @jellyfin host jellyfin.localhost jellyfin
        handle @jellyfin {
          reverse_proxy 127.0.0.1:18096
        }

        ${hyperhdrRoute "hyperhdr.localhost hyperhdr"}
        @nextcloud host nextcloud.localhost nextcloud
        handle @nextcloud {
          reverse_proxy 127.0.0.1:18089
        }

        @syncthing host syncthing.localhost syncthing
        handle @syncthing {
          reverse_proxy 127.0.0.1:18384 {
            header_up Host localhost:18384
            header_up Origin http://localhost:18384
          }
        }

        @torrent host torrent.localhost torrent
        handle @torrent {
          reverse_proxy 127.0.0.1:18081 {
            header_up Host torrent.${domain}
            header_up Origin https://torrent.${domain}
            header_up Referer https://torrent.${domain}/
            header_up -Authorization
          }
        }

        handle {
          import dashboard_controls
          root * ${dashboard}
          file_server
        }
      }

      :8096 {
        reverse_proxy 127.0.0.1:18096
      }

      :8095 {
        reverse_proxy 127.0.0.1:18089
      }

      :8384 {
        reverse_proxy 127.0.0.1:18384 {
          header_up Host localhost:18384
          header_up Origin http://localhost:18384
        }
      }

      :8082 {
        reverse_proxy 127.0.0.1:18081
      }

      ${domain} {
        import ovh_tls
        import dashboard_controls
        @legacy_desktop path /desktop /desktop/*
        redir @legacy_desktop https://desktop.${domain}/ 308
        encode gzip
        root * ${dashboard}
        file_server
      }

      *.${domain} {
        import ovh_tls
        import browser_desktop
        import browser_terminal
        encode gzip

        @code host code.${domain}
        handle @code {
          reverse_proxy 127.0.0.1:3773
        }

        @ai host ai.${domain}
        handle @ai {
          reverse_proxy 127.0.0.1:3000
        }

        @cloud host cloud.${domain}
        handle @cloud {
          @carddav path /.well-known/carddav
          redir @carddav /remote.php/dav 301
          @caldav path /.well-known/caldav
          redir @caldav /remote.php/dav 301
          reverse_proxy 127.0.0.1:18089
        }

        @media host media.${domain}
        handle @media {
          reverse_proxy 127.0.0.1:18096
        }

        @sync host sync.${domain}
        handle @sync {
          reverse_proxy 127.0.0.1:18384 {
            header_up Host localhost:18384
            header_up Origin http://localhost:18384
          }
        }

        @torrent host torrent.${domain}
        handle @torrent {
          reverse_proxy 127.0.0.1:18081 {
            header_up Host torrent.${domain}
            header_up Origin https://torrent.${domain}
            header_up Referer https://torrent.${domain}/
            header_up -Authorization
          }
        }

        ${hyperhdrRoute "hyperhdr.${domain}"}
        @sunshine host sunshine.${domain}
        handle @sunshine {
          reverse_proxy https://127.0.0.1:47990 {
            # Sunshine serves a self-signed certificate on this loopback hop.
            transport http {
              tls_insecure_skip_verify
            }
          }
        }

        @sys host sys.${domain}
        handle @sys {
          reverse_proxy 127.0.0.1:9090
        }

        handle {
          abort
        }
      }
    '';
  };
}
