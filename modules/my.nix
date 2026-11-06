# Per-machine settings. Each host sets these in hosts/<name>/default.nix;
# shared modules read them instead of hard-coding erebor's values.
# Every setting is a group, so a new option can join it without renaming.
{ config, lib, ... }:

{
  options.my = {
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
    };

    macApproval = {
      enable = lib.mkEnableOption "sudo and polkit approval through a forwarded Mac SSH agent";
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
}
