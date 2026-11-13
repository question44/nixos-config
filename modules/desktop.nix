# Intel graphics and Wayland session variables shared by every compositor.
{
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    let
      isx86 = pkgs.stdenv.hostPlatform.isx86_64;
    in
    {
      # Keep Intel graphics available alongside the optional host NVIDIA driver.
      # 32-bit graphics and Intel are x86 only (the aarch64 mac-vm has neither).
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = isx86;
      # First, ahead of the Umbriel and NVIDIA layers; module nesting would
      # otherwise decide the order, which Steam's FHS env (and its hash) follows.
      hardware.graphics.extraPackages = lib.mkIf isx86 (lib.mkBefore [ pkgs.intel-media-driver ]);
      services.xserver.videoDrivers = [ "modesetting" ];
      boot.initrd.kernelModules = lib.mkIf isx86 [ "i915" ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };
    };
}
