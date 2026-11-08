# erebor: the desktop this repository deploys. Hardware, boot and storage are
# in this directory; everything shared comes from the workstation aspect.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.nixosConfigurations.erebor = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ nixos.erebor ];
  };

  flake.modules.nixos.erebor =
    { lib, pkgs, ... }:

    {
      imports = with nixos; [
        ./_hardware-configuration.nix
        erebor-boot
        erebor-storage
        # Hardware-specific aspects.
        xremap
        workstation
        nvidia
        windows-vm
        looking-glass
      ];

      my = {
        user = {
          name = "janzon";
          description = "Janzon";
        };
        network = {
          domain = "erebor.jzon.pl";
          lanInterface = "br0";
        };
        ambilight = {
          enable = true;
          musicSink = "alsa_output.usb-iFi__by_AMR__iFi__by_AMR__HD_USB_Audio_0003-00.analog-stereo";
          wledUrl = "http://192.168.1.118";
        };
        xremap = {
          devices = [
            "Telink IQUNIX 2.4GHz"
            {
              name = "RDR IQUNIX MQ80 KB";
              usb = {
                vendor = "320f";
                product = "5055";
              };
            }
            "Logitech G502 X LS"
          ];
        };
        yubikey = {
          enable = true;
          sound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/dialog-question.ogg";
        };
        macApproval = {
          enable = true;
          addresses = [
            "100.127.94.102"
            "192.168.1.97"
          ];
        };
        nanokvm = {
          enable = true;
          url = "https://kvm-37ff.tail517bdc.ts.net:8443";
        };
        niri = {
          enable = true;
        };
        taskBoard = {
          enable = true;
          linkBase = "https://github.com/question44/nixos-config/blob/master/";
        };
        torrentVpn.enable = false;
        updateBranch.enable = true;
        timeMachine = {
          enable = true;
          path = "/srv/external/expansion/TimeMachine";
          maxSize = "2T";
        };
        streaming = {
          sunshine.enable = true;
          moonshine.enable = true;
        };
        services = {
          jellyfin.enable = true;
          nextcloud.enable = true;
          syncthing.enable = true;
          qbittorrent.enable = true;
          ollama.enable = true;
          t3code.enable = true;
          cockpit.enable = true;
        };
      };

      # Shut down windows11 before toggling GPU ownership.
      virtualisation.windowsGpuPassthrough.enable = false;

      # A second GRUB entry boots with the RTX 4090 reserved for windows11 and
      # Linux on Intel graphics; the default entry stays as above. Switch by
      # rebooting: the GPU binds early in boot, so live switching is unsupported.
      specialisation.gpu-passthrough.configuration = {
        system.nixos.tags = [ "gpu-passthrough" ];
        virtualisation.windowsGpuPassthrough.enable = lib.mkForce true;
      };

      # Keep P-core 0 (CPUs 0-1) free of Nix builds so the desktop stays responsive.
      systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "2-19";

      # systemd-oomd never kills the session core; desktop helpers go last.
      systemd.user.services =
        lib.genAttrs
          [
            "umbriel"
            "xremap"
            "pipewire"
            "pipewire-pulse"
            "wireplumber"
            "dbus-broker"
          ]
          (_: {
            serviceConfig.ManagedOOMPreference = "omit";
          })
        //
          lib.genAttrs
            [
              "noctalia"
              "oo7-daemon"
              "xdg-desktop-portal"
              "xdg-desktop-portal-umbriel"
              "yubikey-touch-notify"
            ]
            (_: {
              serviceConfig.ManagedOOMPreference = "avoid";
            });

      # Keep NetworkManager off the NanoKVM's USB Ethernet gadget (reached over
      # Tailscale instead). With an address on it, HyperHDR and KDE Connect announce
      # erebor.local with that address over mDNS, so Avahi renames itself erebor-2.
      services.udev.extraRules = ''
        ACTION!="remove", SUBSYSTEM=="net", ATTRS{idVendor}=="3346", ATTRS{idProduct}=="1009", ENV{NM_UNMANAGED}="1"
      '';

      networking.hostName = "erebor";

      system.stateVersion = "26.05";
    };
}
