{ config, lib, ... }:

lib.mkIf (!config.virtualisation.windowsGpuPassthrough.enable) {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  boot.kernelParams = [ "nvidia_drm.modeset=1" ];
}
