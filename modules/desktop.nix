{ ... }:

{
  environment.etc."xdg/niri/config.kdl".source = ../home/niri/config.kdl;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };
}
