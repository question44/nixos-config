# Unfree allowlist, system packages, application menu and Flatpak.
{
  config,
  darkly,
  lib,
  pkgs,
  vicinae,
  monstar,
  claude-desktop-nix,
  zen-browser,
  ...
}:
let
  hyperhdr = pkgs.callPackage ../../packages/hyperhdr.nix { };
  aiUsagebar = pkgs.callPackage ../../packages/ai-usagebar.nix { };
  auroraNcs = pkgs.callPackage ../../packages/aurora-ncs.nix { };
  ut2004 = pkgs.callPackage ../../packages/ut2004.nix { };
  noctaliaPython = pkgs.callPackage ../../packages/noctalia-python.nix { };
  noctaliaPkgConfig = pkgs.writeShellScriptBin "pkg-config" ''
    export PKG_CONFIG_PATH="${pkgs.pipewire.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    exec ${pkgs.pkg-config}/bin/pkg-config "$@"
  '';

  system = pkgs.stdenv.hostPlatform.system;
  claudeDesktop = claude-desktop-nix.packages.${system}.default.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram "$out/bin/claude-desktop" \
        --add-flags "--password-store=gnome-libsecret"
    '';
  });
  # Phone Connect invokes gdbus through Noctalia's PATH; only gdbus, not all of glib.bin.
  gdbus = pkgs.runCommand "gdbus" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.glib.bin}/bin/gdbus $out/bin/gdbus
  '';
  # KDialog needs KIO's thumbnail worker and image providers too.
  kdialog = pkgs.writeShellScriptBin "kdialog" ''
    export QT_PLUGIN_PATH="${pkgs.kdePackages.kio-extras}/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    export XDG_DATA_DIRS="${pkgs.kdePackages.kio-extras}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    exec ${pkgs.kdePackages.kdialog}/bin/kdialog "$@"
  '';

  # Tauon imports pypresence for Discord Rich Presence, but nixpkgs ships it with
  # lynxpresence; nixpkgs' pypresence predates the StatusDisplayType it needs.
  tauon = pkgs.tauon.overridePythonAttrs (old: {
    pythonPath = old.pythonPath ++ [
      (pkgs.python3Packages.pypresence.overridePythonAttrs {
        version = "4.6.2";
        src = pkgs.fetchPypi {
          pname = "pypresence";
          version = "4.6.2";
          hash = "sha256-fn6T3g6UpCMUMA720V3SxExk73S3x0kkO8Imviq5Boc=";
        };
      })
    ];
  });

  spotifyLauncher = pkgs.writeShellScriptBin "spotify-launcher" ''
    exec /run/current-system/sw/bin/spotify "$@"
  '';

  # essential [--omit] <command> [args]: run a command in its own user scope
  # that systemd-oomd kills last (avoid) or never (--omit) until it exits.
  essential = pkgs.writeShellApplication {
    name = "essential";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      pref=avoid
      if [ "''${1:-}" = --omit ]; then
        pref=omit
        shift
      fi
      if [ $# -eq 0 ]; then
        echo "usage: essential [--omit] <command> [args...]" >&2
        exit 2
      fi
      exec systemd-run --user --scope --quiet --collect \
        --unit="essential-$(basename "$1")-$$" \
        -p ManagedOOMPreference="$pref" -- "$@"
    '';
  };
in
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-kernel-modules"
      "nvidia-settings"
      "cccl"
      "cuda_compat"
      "cuda_crt"
      "cuda_cudart"
      "cuda_nvcc"
      "cuda_nvrtc"
      "libcublas"
      "libnvvm"
      "open-webui"
      "spotify"
      "discord"
      "discord-unwrapped"
      "stremio-linux-shell"
      "unrar"
      "steam"
      "steam-unwrapped"
      "google-chrome"
      "claude-code"
    ];

  environment.localBinInPath = true;
  environment.etc."xdg/menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <DefaultMergeDirs/>
      <Include><All/></Include>
    </Menu>
  '';
  environment.systemPackages =
    with pkgs;
    [
      essential
      lsof
      google-authenticator
      proton-vpn
      oo7
      nodejs
      gh
      awscli2
      aws-sam-cli
      gnupg
      gnumake
      kdePackages.dolphin
      kdePackages.discover
      kdePackages.konsole
      kdePackages.gwenview
      kdePackages.okular
      kdePackages.ark
      # System Monitor app; ksystemstats provides its D-Bus sensor backend outside Plasma.
      kdePackages.plasma-systemmonitor
      kdePackages.ksystemstats
      kdePackages.kinfocenter
      # Storage Device Health page; kded6 is D-Bus activated to run its SMART module.
      kdePackages.plasma-disks
      kdePackages.kded
      smartmontools
      (google-chrome.override { commandLineArgs = "--password-store=gnome-libsecret"; })
      haruna
      moonlight-qt
      stremio-linux-shell
      ddcutil
      kdePackages.breeze
      candy-icons
      darkly.packages.${pkgs.stdenv.hostPlatform.system}.darkly-qt6
      (discord.override { withVencord = true; })
      vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default
      ghostty
      xwayland-satellite
      wl-clipboard
      wlr-randr
      pavucontrol
      tuigreet
      xremap
    ]
    ++ lib.optionals config.my.ambilight.enable [
      hyperhdr
    ]
    ++ [
      # Renderer for the janzon/wallpaper-engine Noctalia plugin.
      linux-wallpaperengine
      aiUsagebar
      auroraNcs
      ut2004.ut2004
      ut2004.ut2004-import-rpm
      ut2004.ut2004-setup
      noctaliaPython
      spotifyLauncher
      cava
      jq
      playerctl
      spotify-player
      libnotify
      gtk3
      gtk-layer-shell
      xdg-utils
      bitwarden-cli
      hyprpicker
      efibootmgr
      cryptsetup
      grim
      kdePackages.kdeconnect-kde
      sshfs
      qrencode
      speedtest
      slurp
      tesseract
      imagemagick
      zbar
      translate-shell
      ffmpeg
      gpu-screen-recorder
      wl-screenrec
      wf-recorder
      bc
      pulseaudio
      mpv
      # Music player; reads CUE sheets for single-file album rips.
      tauon
      fooyin
      noctaliaPkgConfig
      pipewire.dev
      sway
    ]
    ++ [
      zen-browser.packages.${system}.default
      monstar.packages.${system}.default
      (callPackage ../../packages/umbriel-display-mode.nix { })
      claudeDesktop
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
      gdbus
      kdialog
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

  services.flatpak.enable = true;
  systemd.services.flatpak-flathub = {
    description = "Register the Flathub Flatpak repository";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
}
