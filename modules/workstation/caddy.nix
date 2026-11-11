# Caddy reverse proxy for local names and *.erebor.jzon.pl.
{
  flake.modules.nixos.caddy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domain = config.my.network.domain;
      ovhKeys = [
        "ovh_endpoint"
        "ovh_application_key"
        "ovh_application_secret"
        "ovh_consumer_key"
      ];
      ovhDns = config.my.network.ovhDns.enable;
      dashboard = config.services.erebor-dashboard.package;
      # Spliced into the indented Caddyfile below; the text keeps its layout.
      hyperhdrRoute =
        hosts:
        lib.optionalString config.my.ambilight.enable "@hyperhdr host ${hosts}\n  handle @hyperhdr {\n    reverse_proxy 127.0.0.1:8090\n  }\n";

      # Routes generated from my.services (modules/my.nix). Caddy reformats the
      # file, so indentation here does not matter.
      services = lib.filter (s: s.enable) (lib.attrValues config.my.services);
      withLocal = lib.filter (s: s.localName != null) services;
      withLan = lib.filter (s: s.lanPort != null) services;
      withPublic = lib.filter (s: s.publicName != null) services;
      proxy =
        s: headers:
        let
          upstream = "${if s.proxy.https then "https://" else ""}127.0.0.1:${toString s.port}";
          body =
            map (h: "header_up ${h}") headers
            ++ lib.optional s.proxy.tlsInsecure "transport http {\ntls_insecure_skip_verify\n}";
        in
        if body == [ ] then
          "reverse_proxy ${upstream}\n"
        else
          "reverse_proxy ${upstream} {\n${lib.concatLines body}}\n";
      route = matcher: hosts: body: ''
        @${matcher} host ${hosts}
        handle @${matcher} {
        ${body}}
      '';
      localRoutes = lib.concatMapStrings (
        s: route s.localName "${s.localName}.localhost ${s.localName}" (proxy s s.proxy.headers)
      ) withLocal;
      lanBlocks = lib.concatMapStrings (s: ''
        :${toString s.lanPort} {
        ${proxy s s.proxy.lanHeaders}}
      '') withLan;
      publicRoutes = lib.concatMapStrings (
        s: route s.publicName "${s.publicName}.${domain}" (s.extraConfig + proxy s s.proxy.headers)
      ) withPublic;
    in
    {
      # OVH DNS API credentials for certificates, from secrets/<host>.yaml.
      sops = lib.mkIf ovhDns {
        secrets = lib.genAttrs ovhKeys (_: { });
        templates."caddy-ovh.env" = {
          content = lib.concatMapStrings (k: "${lib.toUpper k}=${config.sops.placeholder.${k}}\n") ovhKeys;
          owner = "caddy";
          restartUnits = [ "caddy.service" ];
        };
      };

      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/ovh@v1.1.0" ];
          hash = "sha256-VJgAmT1q1wcqt7o7HrK2+ONfZrfI/QW2v3d6ZSMh718=";
        };
        environmentFile = lib.mkIf ovhDns config.sops.templates."caddy-ovh.env".path;
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
            ${lib.optionalString ovhDns ''
              tls {
                dns ovh {
                  endpoint {$OVH_ENDPOINT}
                  application_key {$OVH_APPLICATION_KEY}
                  application_secret {$OVH_APPLICATION_SECRET}
                  consumer_key {$OVH_CONSUMER_KEY}
                }
                resolvers 1.1.1.1 9.9.9.9
              }
            ''}
          }

          :80 {
            @domain host ${domain} *.${domain}
            redir @domain https://{host}{uri} permanent

            ${localRoutes}
            ${hyperhdrRoute "hyperhdr.localhost hyperhdr"}
            handle {
              import dashboard_controls
              root * ${dashboard}
              file_server
            }
          }

          ${lanBlocks}
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

            ${publicRoutes}
            ${hyperhdrRoute "hyperhdr.${domain}"}
            handle {
              abort
            }
          }
        '';
      };
    };
}
