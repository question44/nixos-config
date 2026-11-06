# Per-machine settings. Each host sets these in hosts/<name>/default.nix;
# shared modules read them instead of hard-coding erebor's values.
{ lib, ... }:

{
  options.my = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "The main desktop user's login name.";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      example = "erebor.jzon.pl";
      description = "Public domain; services are served on its subdomains.";
    };

    ambilight.enable = lib.mkEnableOption "HyperHDR ambient lighting from screen capture";
    yubikey.enable = lib.mkEnableOption "YubiKey (pam_u2f) touch for sudo, with a touch notification";
    macApproval.enable = lib.mkEnableOption "sudo and polkit approval through a forwarded Mac SSH agent";
    nanokvm = {
      enable = lib.mkEnableOption "NanoKVM wake and outlet readings in the dashboard";
      url = lib.mkOption {
        type = lib.types.str;
        example = "https://kvm-37ff.tail517bdc.ts.net:8443";
        description = "Base URL of the wake helper installed on the NanoKVM.";
      };
    };
    wledUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "WLED controller the dashboard's ambilight buttons switch.";
    };
  };
}
