{ config, lib, pkgs, ... }:

{
  # Keep Intel graphics available alongside the optional host NVIDIA driver.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  services.xserver.videoDrivers = [ "modesetting" ];
  boot.initrd.kernelModules = [ "i915" ];

  environment.etc."xdg/niri/config.kdl" = lib.mkIf config.my.niri.enable {
    source = ../home/niri/config.kdl;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };
}
