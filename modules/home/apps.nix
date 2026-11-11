# Linux application configs: the Zed keymap, Monstar, the Noctalia Zed template (both share
# the app opacity with Ghostty, see _opacity.nix) and Vencord. Neovim and
# Ghostty are their own aspects (nvim.nix, ghostty.nix).
{
  flake.modules.homeManager.apps =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      opacity = import ./_opacity.nix lib;
    in
    {
      # Zed: macOS JetBrains keymap with Cmd on Super (SYS-093). Live link into
      # the checkout so Zed's keymap editor can still save to it;
      # regenerate with home/zed/generate-keymap.py after a Zed upgrade.
      xdg.configFile."zed/keymap.json".source =
        config.lib.file.mkOutOfStoreSymlink "${osConfig.my.flakePath}/home/zed/keymap.json";
      # Monstar shares Ghostty's background opacity, per theme mode: the link
      # points at the variant erebor-theme-opacity picked (theme-opacity.nix).
      xdg.configFile."monstar/config".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/erebor-theme-opacity/monstar";
      xdg.configFile."noctalia/templates/zed.json".source =
        pkgs.replaceVars ../../home/noctalia/templates/zed.json
          {
            appOpacityAlpha = opacity.dark.alpha;
            appOpacityAlphaLight = opacity.light.alpha;
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
