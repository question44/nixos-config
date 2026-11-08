# Intel graphics and Wayland session variables shared by every compositor.
{
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    {
      # Keep Intel graphics available alongside the optional host NVIDIA driver.
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      # First, ahead of the Umbriel and NVIDIA layers; module nesting would
      # otherwise decide the order, which Steam's FHS env (and its hash) follows.
      hardware.graphics.extraPackages = lib.mkBefore [ pkgs.intel-media-driver ];
      services.xserver.videoDrivers = [ "modesetting" ];
      boot.initrd.kernelModules = [ "i915" ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };
    };
}
