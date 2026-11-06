# uinput access and the xremap key remapper.
{ lib, pkgs, ... }:
{
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", TAG+="uaccess"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="320f", ATTR{idProduct}=="5055", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="xremap-restart.service"
  '';

  systemd.user.services.xremap = {
    description = "xremap key remapper";
    # Apps launched by xremap inherit this PATH. Keep the setuid wrappers first
    # and use profile links, not store paths, so sudo works and survives rebuilds.
    environment.PATH = lib.mkForce "/run/wrappers/bin:/home/janzon/.local/bin:/home/janzon/.nix-profile/bin:/etc/profiles/per-user/janzon/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xremap}/bin/xremap --allow-launch true --mouse --device \"Telink IQUNIX 2.4GHz\" --device \"RDR IQUNIX MQ80 KB\" --device \"Logitech G502 X LS\" /home/janzon/.config/xremap/config.yml";
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
}
