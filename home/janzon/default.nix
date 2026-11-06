# Home Manager configuration for janzon, split by topic so parallel
# changes rarely touch the same file.
{ config, lib, pkgs, umbriel, monstar, claude-desktop-nix, zen-browser, ... }:
let
  zenPackages = zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
  zenBrowser = zenPackages.default;
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
  # Phone Connect invokes gdbus through Noctalia's existing PATH.
  home.file.".local/bin/gdbus".source = "${pkgs.glib.bin}/bin/gdbus";
  home.file.".local/bin/kdialog".source = pkgs.writeShellScript "kdialog" ''
    # KDialog needs KIO's thumbnail worker and image providers too.
    export QT_PLUGIN_PATH="${pkgs.kdePackages.kio-extras}/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    export XDG_DATA_DIRS="${pkgs.kdePackages.kio-extras}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    exec ${pkgs.kdePackages.kdialog}/bin/kdialog "$@"
  '';
  home.packages = with pkgs; [
    zenBrowser
    monstar.packages.${pkgs.stdenv.hostPlatform.system}.default
    (callPackage ../../packages/umbriel-display-mode.nix { })
    (claude-desktop-nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        wrapProgram "$out/bin/claude-desktop" \
          --add-flags "--password-store=gnome-libsecret"
      '';
    }))
    claude-code
    zed-editor
    neovim
    fd
    ripgrep
    btop
    fastfetch
    fortune
    cowsay
    toilet
    eza
    git
    curl
    lazygit
    gcc
    tree-sitter
    # Qt image decoders for Dolphin's thumbnailer (WebP, AVIF, HEIC, JXL, ...).
    kdePackages.qtimageformats
    kdePackages.kimageformats
    kdePackages.qtsvg
    # Extra KIO thumbnailers: video, PDF/PS/RAW/Blender/mobi, gettext.
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kdesdk-thumbnailers
    # Helpers the kio-extras comic (.cbr) and DjVu thumbnailers execute.
    unrar
    djvulibre
  ];
  home.sessionVariables = {
    EDITOR = "${sessionEditor}/bin/session-editor";
    VISUAL = "${sessionEditor}/bin/session-editor";
    GIT_EDITOR = "${sessionEditor}/bin/session-editor";
    QT_STYLE_OVERRIDE = "Darkly";
    STARSHIP_CONFIG = lib.mkForce "${config.home.homeDirectory}/.config/noctalia/starship.toml";
  };
}
