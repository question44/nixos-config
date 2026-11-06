# Home Manager configuration for janzon, split by topic so parallel
# changes rarely touch the same file.
{
  config,
  lib,
  pkgs,
  umbriel,
  ...
}:
let
  sessionEditor = pkgs.writeShellScriptBin "session-editor" ''
    if [ -n "''${WAYLAND_DISPLAY:-}" ] \
      && [ -n "''${XDG_RUNTIME_DIR:-}" ] \
      && [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
      exec ${pkgs.zed-editor}/bin/zeditor --wait "$@"
    fi
    if [ -n "''${DISPLAY:-}" ]; then
      exec ${pkgs.zed-editor}/bin/zeditor --wait "$@"
    fi
    exec ${pkgs.neovim}/bin/nvim "$@"
  '';
in
{
  imports = [
    umbriel.homeModules.default
    ./shell.nix
    ./desktop.nix
    ./apps.nix
    ./compositor.nix
  ];
  home.stateVersion = "26.05";
  home.pointerCursor = {
    enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };
  home.sessionVariables = {
    EDITOR = "${sessionEditor}/bin/session-editor";
    VISUAL = "${sessionEditor}/bin/session-editor";
    GIT_EDITOR = "${sessionEditor}/bin/session-editor";
    QT_STYLE_OVERRIDE = "Darkly";
    STARSHIP_CONFIG = lib.mkForce "${config.home.homeDirectory}/.config/noctalia/starship.toml";
  };
}
