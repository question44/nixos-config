{ config, lib, ... }:

lib.mkIf (!config.virtualisation.windowsGpuPassthrough.enable) {
  # Ada and newer Nouveau GPUs require the signed NVIDIA GSP firmware.  It is
  # provided by hardware.enableRedistributableFirmware in the host config.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Mesa selects NVK automatically for Vulkan on this Nouveau-driven GPU.
  services.xserver.videoDrivers = [ "nouveau" ];
  boot.kernelParams = [ "nouveau.config=NvGspRm=1" ];
  boot.initrd.kernelModules = lib.optionals config.boot.plymouth.enable [ "nouveau" ];
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];
}
