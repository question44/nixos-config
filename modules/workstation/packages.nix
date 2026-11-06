# Unfree allowlist, system packages, application menu and Flatpak.
{ config, darkly, lib, pkgs, vicinae, ... }:
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

  spotifyLauncher = pkgs.writeShellScriptBin "spotify-launcher" ''
    exec /run/current-system/sw/bin/spotify "$@"
  '';
in
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-kernel-modules"
      "nvidia-settings"
      "cuda_cccl"
      "cuda_cudart"
      "cuda_nvcc"
      "libcublas"
      "open-webui"
      "spotify"
      "discord"
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
  environment.systemPackages = with pkgs; [
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
  ] ++ lib.optionals config.my.ambilight.enable [
    hyperhdr
  ] ++ [
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
    noctaliaPkgConfig
    pipewire.dev
    sway
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
