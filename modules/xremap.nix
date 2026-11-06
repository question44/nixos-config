# uinput access and the xremap key remapper.
{ config, lib, pkgs, ... }:
let
  user = config.my.user;
  cfg = config.my.xremap;
  deviceArgs = lib.concatMapStrings (d: "--device \"${d}\" ") cfg.devices;
in
{
  options.my.xremap = {
    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Input device names xremap grabs (see `xremap --list-devices`).";
    };
    restartOnUsb = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options.vendor = lib.mkOption { type = lib.types.str; };
        options.product = lib.mkOption { type = lib.types.str; };
      });
      default = null;
      description = "USB receiver whose hot-plug restarts xremap, so it grabs the new device.";
    };
  };

  config = {
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", TAG+="uaccess"
  '' + lib.optionalString (cfg.restartOnUsb != null) ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${cfg.restartOnUsb.vendor}", ATTR{idProduct}=="${cfg.restartOnUsb.product}", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="xremap-restart.service"
  '';

  systemd.user.services.xremap = {
    description = "xremap key remapper";
    # Apps launched by xremap inherit this PATH. Keep the setuid wrappers first
    # and use profile links, not store paths, so sudo works and survives rebuilds.
    environment.PATH = lib.mkForce "/run/wrappers/bin:/home/${user}/.local/bin:/home/${user}/.nix-profile/bin:/etc/profiles/per-user/${user}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xremap}/bin/xremap --allow-launch true --mouse ${deviceArgs}/home/${user}/.config/xremap/config.yml";
      Restart = "on-failure";
    };
  };

  systemd.user.services.xremap-restart = {
    description = "Restart xremap after keyboard connection";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart xremap.service";
    };
  };
  };
}
