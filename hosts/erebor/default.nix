{ ... }:

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
      devices = [ "Telink IQUNIX 2.4GHz" "RDR IQUNIX MQ80 KB" "Logitech G502 X LS" ];
      restartOnUsb = { vendor = "320f"; product = "5055"; };
    };
    yubikey = {
      enable = true;
    };
    macApproval = {
      enable = true;
    };
    nanokvm = {
      enable = true;
      url = "https://kvm-37ff.tail517bdc.ts.net:8443";
    };
  };

  # Shut down windows11 before toggling GPU ownership.
  virtualisation.windowsGpuPassthrough.enable = false;

  networking.hostName = "erebor";

  system.stateVersion = "26.05";
}
