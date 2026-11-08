# Linux application configs: Monstar, the Noctalia Zed template (both share
# the app opacity with Ghostty, see _opacity.nix) and Vencord. Neovim and
# Ghostty are their own aspects (nvim.nix, ghostty.nix).
{
  flake.modules.homeManager.apps =
    { lib, pkgs, ... }:
    let
      opacity = import ./_opacity.nix lib;
    in
    {
      # Monstar shares Ghostty's background opacity (_opacity.nix).
      xdg.configFile."monstar/config".source = pkgs.replaceVars ../../home/monstar/config {
        appOpacity = opacity.value;
      };
      xdg.configFile."noctalia/templates/zed.json".source =
        pkgs.replaceVars ../../home/noctalia/templates/zed.json
          {
            appOpacityAlpha = opacity.alpha;
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
    };
}
