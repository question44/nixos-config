# Ghostty's config. On Linux it uses Noctalia's generated theme and the shared
# opacity; on macOS, which has no Noctalia, home/ghostty/config-macos.ghostty
# with a fixed theme. Ghostty itself comes from the system or a Homebrew cask.
{
  flake.modules.homeManager.ghostty =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      xdg.configFile."ghostty/config.ghostty".source =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ../../home/ghostty/config-macos.ghostty
        else
          pkgs.replaceVars ../../home/ghostty/config.ghostty {
            appOpacity = (import ./_opacity.nix lib).dark.value;
            opacityFile = "${config.xdg.stateHome}/erebor-theme-opacity/ghostty";
          };
    };
}
