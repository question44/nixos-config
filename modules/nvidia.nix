{ config, lib, ... }:

lib.mkIf (!config.virtualisation.windowsGpuPassthrough.enable) {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "615.78.08";
      sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
      sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
      openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
      settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
      persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
    };
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };

  boot.kernelParams = [ "nvidia_drm.modeset=1" ];
  boot.initrd.kernelModules = lib.optionals config.boot.plymouth.enable [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];
}
