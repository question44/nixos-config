# Per-machine settings. Each host sets these in modules/hosts/<name>/default.nix;
# shared modules read them instead of hard-coding erebor's values.
# Every setting is a group, so a new option can join it without renaming.
{
  flake.modules.nixos.my =
    {
      pkgs,
      config,
      lib,
      ...
    }:

    let
      serviceType = lib.types.submodule (
        { name, ... }: {
          options = {
            enable = lib.mkEnableOption "the ${name} service, with its web routes and LAN port";
            port = lib.mkOption {
              type = lib.types.port;
              description = "Loopback port Caddy proxies to.";
            };
            localName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "jellyfin";
              description = "Bare name served on :80 as `<name>` and `<name>.localhost`, also added to /etc/hosts.";
            };
            publicName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "media";
              description = "Subdomain of my.network.domain served over HTTPS.";
            };
            lanPort = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              description = "Plain-HTTP port Caddy listens on, opened on the LAN interface.";
            };
            proxy = {
              headers = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [
                  "Host localhost:18384"
                  "-Authorization"
                ];
                description = "`header_up` arguments for the local and public routes.";
              };
              lanHeaders = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = config.my.services.${name}.proxy.headers;
                defaultText = lib.literalExpression "proxy.headers";
                description = "`header_up` arguments for the LAN port block.";
              };
              https = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "The upstream speaks HTTPS.";
              };
              tlsInsecure = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Skip upstream certificate checks (self-signed loopback HTTPS).";
              };
            };
            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Caddy directives placed before reverse_proxy in the public route.";
            };
          };
        }
      );
    in
    {
      options.my = {
        services = lib.mkOption {
          type = lib.types.attrsOf serviceType;
          default = { };
          description = ''
            Web services behind Caddy. Each modules/services file declares its
            entry; hosts set `my.services.<name>.enable`. Routes, /etc/hosts names
            and LAN firewall ports are generated from this registry.
          '';
        };

        niri = {
          enable = lib.mkEnableOption "Niri as a second compositor next to Umbriel";
        };

        torrentVpn = {
          enable = lib.mkEnableOption "qBittorrent only through the Proton VPN tunnel, on Proton's forwarded port";
        };

        streaming = {
          sunshine.enable = lib.mkEnableOption "the Sunshine game-streaming setup (wrapper, output helper, route)";
          moonshine.enable = lib.mkEnableOption "the Moonshine game-streaming server";
        };

        user = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "The main desktop user's login name.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = config.my.user.name;
            defaultText = lib.literalExpression "config.my.user.name";
            description = "The main user's full name.";
          };
        };

        network = {
          domain = lib.mkOption {
            type = lib.types.str;
            example = "erebor.jzon.pl";
            description = "Public domain; services are served on its subdomains.";
          };
          lanInterface = lib.mkOption {
            type = lib.types.str;
            example = "br0";
            description = "LAN interface whose firewall allows local services (SSH, media, sync).";
          };
        };

        ambilight = {
          enable = lib.mkEnableOption "HyperHDR ambient lighting from screen capture";
          musicSink = lib.mkOption {
            type = lib.types.str;
            example = "alsa_output.usb-iFi__by_AMR__iFi__by_AMR__HD_USB_Audio_0003-00.analog-stereo";
            description = "PipeWire sink whose output HyperHDR captures for music effects (`pw-cli ls Node`).";
          };
          wledUrl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "http://192.168.1.118";
            description = "WLED controller the dashboard's ambilight buttons switch.";
          };
        };

        yubikey = {
          enable = lib.mkEnableOption "YubiKey (pam_u2f) touch for sudo, with a touch notification";
          sound = lib.mkOption {
            type = lib.types.str;
            default = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-information.oga";
            defaultText = lib.literalExpression ''"''${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-information.oga"'';
            example = lib.literalExpression ''"''${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/dialog-question.ogg"'';
            description = "Sound played (with pw-play) while the YubiKey waits for a touch.";
          };
        };

        macApproval = {
          enable = lib.mkEnableOption "sudo and polkit approval through a forwarded Mac SSH agent";
          addresses = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "100.127.94.102"
              "192.168.1.97"
            ];
            description = "The Mac's Tailscale and LAN addresses; sshd drops its sessions when it sleeps.";
          };
        };

        nanokvm = {
          enable = lib.mkEnableOption "NanoKVM wake and outlet readings in the dashboard";
          url = lib.mkOption {
            type = lib.types.str;
            example = "https://kvm-37ff.tail517bdc.ts.net:8443";
            description = "Base URL of the wake helper installed on the NanoKVM.";
          };
        };
      };
    };
}
