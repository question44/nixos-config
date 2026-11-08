# Darkly, the Qt application style: installed system-wide and selected for
# the user's Qt apps.
{ inputs, ... }:
{
  flake.modules.nixos.darkly =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.darkly.packages.${pkgs.stdenv.hostPlatform.system}.darkly-qt6
      ];
    };

  flake.modules.homeManager.darkly = {
    qt.style.package = inputs.darkly.packages.x86_64-linux.darkly-qt6;
    home.sessionVariables.QT_STYLE_OVERRIDE = "Darkly";
  };
}
