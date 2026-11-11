# Unfree allowlist, system packages and application menu.
{ inputs, ... }:
{
  flake.modules.nixos.packages =
    {
      config,
      lib,
      pkgs,
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
      chomik = inputs.chomik.packages.${system}.default;
      vitrum = inputs.vitrum.packages.${system}.default;
      # The app turns hardware acceleration off for good when its GPU process
      # fails to relaunch, which a nixos-rebuild switch triggers by killing its
      # helpers. Clear that flag at every launch so one switch does not leave it
      # on software rendering; a real GPU failure still disables it per run.
      claudeDesktop = inputs.claude-desktop-nix.packages.${system}.default.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeShellWrapper ];
        postFixup = (old.postFixup or "") + ''
          wrapProgramShell "$out/bin/claude-desktop" \
            --add-flags "--password-store=gnome-libsecret" \
            --run 'cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/Claude/claude_desktop_config.json"; [ -f "$cfg" ] && ${pkgs.gnused}/bin/sed -i -E "s/(\"isHardwareAcceleration(Auto)?Disabled\"): *true/\1: false/" "$cfg" || true'
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
      # kio-admin's privileged helper is a D-Bus system service.
      services.dbus.packages = [ pkgs.kdePackages.kio-admin ];

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
          # Dolphin's admin mode (admin:/, "Open as Administrator"), approved through polkit.
          kdePackages.kio-admin
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
          haruna
          moonlight-qt
          # WhatsApp Web client (Qt WebEngine).
          zapzap
          stremio-linux-shell
          # Windows-only apps such as ChomikBox, each in its own prefix under
          # ~/.local/share/wineprefixes.
          wineWow64Packages.stable
          winetricks
          ddcutil
          kdePackages.breeze
          candy-icons
          (discord.override {
            withVencord = true;
            # nixpkgs still ships Vencord 1.15.13, which hangs Discord on "Starting..."
            # after Discord's Nov 2026 rspack update; 1.15.16 fixes it. Drop this
            # override once nixpkgs packages 1.15.16 or newer.
            vencord = vencord.overrideAttrs (
              finalAttrs: old: {
                version = "1.15.16";
                src = old.src.override {
                  tag = "v${finalAttrs.version}";
                  hash = "sha256-aUJubLJpyLAZWiOezqFxPY6oVPgWVPQpajFqrJvrO9U=";
                };
                # Upstream now pins @types/react 19, so the nixpkgs lockfile fix
                # is obsolete and no longer applies.
                patches = [ ];
                postPatch = "";
                pnpmDeps = old.pnpmDeps.overrideAttrs {
                  inherit (finalAttrs) src patches postPatch;
                  outputHash = "sha256-HS8uZNepvDefjrsG3buVLFCVv7sHvazcwdpcT3EQ/78=";
                };
              }
            );
          })
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
          # Chomikuj.pl client; also the chomik:// link handler (modules/home/desktop.nix).
          chomik
          # Liquid glass demo for the umbriel_glass_v1 patch (glass.toml has its rule).
          vitrum
          ut2004.ut2004
          ut2004.ut2004-import-rpm
          ut2004.ut2004-setup
          noctaliaPython
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
          (tesseract.override {
            enableLanguages = [
              "eng"
              "pol"
            ];
          })
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
          fooyin
          noctaliaPkgConfig
          pipewire.dev
          sway
        ]
        ++ [
          inputs.zen-browser.packages.${system}.default
          inputs.monstar.packages.${system}.default
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

    };
}
