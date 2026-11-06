{ lib, pkgs, ... }:

{
  imports = [
    ../../modules/workstation/base.nix
    ./hardware-configuration.nix
    ./boot.nix
    ./storage.nix
    ../../modules/xremap.nix
    ../../modules/workstation
    ../../modules/nvidia.nix
    ../../modules/windows-vm.nix
    ../../modules/looking-glass.nix
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
    torrentVpn.enable = false;
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

  networking.hostName = "erebor";

  system.stateVersion = "26.05";
}
