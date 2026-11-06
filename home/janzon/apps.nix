# Application configs: Neovim, Ghostty, Monstar, Noctalia, Zed and Vencord.
{ lib, pkgs, ... }:
let
  appearance = import ../appearance.nix;
  # Zed uses an 8-bit alpha; use the same rounded value in Ghostty.
  appOpacityByte =
    assert lib.assertMsg (
      appearance.appOpacity >= 0 && appearance.appOpacity <= 1
    ) "appearance.appOpacity must be between 0 and 1";
    builtins.floor (appearance.appOpacity * 255 + 0.5);
  appOpacityAlpha = lib.toUpper (lib.fixedWidthString 2 "0" (lib.toHexString appOpacityByte));
in
{
  xdg.configFile."nvim".source = ../nvim;
  xdg.configFile."ghostty/config.ghostty".source = pkgs.replaceVars ../ghostty/config.ghostty {
    appOpacity = builtins.toJSON (appOpacityByte / 255.0);
  };
  # Monstar shares Ghostty's background opacity, from home/appearance.nix.
  xdg.configFile."monstar/config".source = pkgs.replaceVars ../monstar/config {
    appOpacity = builtins.toJSON (appOpacityByte / 255.0);
  };
  xdg.configFile."noctalia/config.toml".source = ../noctalia/config.toml;
  # Local plugins in the data dir outrank every plugin source.
  xdg.dataFile."noctalia/plugins/wallpaper-engine".source = ../noctalia/plugins/wallpaper-engine;
  xdg.configFile."noctalia/templates/zed.json".source =
    pkgs.replaceVars ../noctalia/templates/zed.json
      {
        inherit appOpacityAlpha;
      };
  # Keep Vencord settings writable and let Noctalia generate its CSS.
  home.activation.discordNoctaliaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/Vencord/themes" "$HOME/.config/Vencord/settings"
    settings="$HOME/.config/Vencord/settings/settings.json"
    if [ ! -e "$settings" ]; then
      run ${pkgs.coreutils}/bin/install -m 600 ${
        pkgs.writeText "vencord-noctalia-settings.json" (
          builtins.toJSON {
            enabledThemes = [ "noctalia.theme.css" ];
          }
        )
      } "$settings"
    fi
  '';
}
