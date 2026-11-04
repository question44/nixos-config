{
  description = "Minimal NixOS installation for erebor";

  inputs = {
    self.submodules = true;
    dashboard = {
      url = "path:./apps/erebor-dashboard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonshine = {
      url = "github:hgaiser/moonshine/79554f853135cbac44502b58093a4eb0f0f5e6f1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop-nix.url = "github:tomsch/claude-desktop-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umbriel.url = "github:noctalia-dev/umbriel";
    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darkly = {
      url = "github:Bali10050/Darkly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae.url = "github:vicinaehq/vicinae";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, claude-desktop-nix, moonshine, dashboard, noctalia, noctalia-greeter, umbriel, millennium, helium, zen-browser, darkly, vicinae, home-manager, ... }:
    {
      nixosConfigurations.erebor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit darkly vicinae; };
        modules = [
          moonshine.nixosModules.default
          ./modules/moonshine.nix
          ./hosts/erebor/default.nix
          noctalia-greeter.nixosModules.default
          noctalia.nixosModules.default
          umbriel.nixosModules.default
          dashboard.nixosModules.default
          ./modules/dashboard-control.nix
          helium.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ millennium.overlays.default ];
            # Home Manager uses the modern profile CLI during system activation.
            systemd.services.home-manager-janzon.environment.NIX_CONFIG =
              "experimental-features = nix-command flakes";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.janzon = { lib, pkgs, ... }:
              let
                zenPackages = zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
                zenBrowser = zenPackages.default;
                rcmdPython = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
                rcmd = pkgs.writeShellScript "rcmd" ''
                  export GI_TYPELIB_PATH="${pkgs.glib.out}/lib/girepository-1.0"
                  export RCMD_GIO="${pkgs.glib.bin}/bin/gio"
                  exec ${rcmdPython}/bin/python3 ${./home/rcmd/rcmd.py} "$@"
                '';
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
              imports = [ umbriel.homeModules.default ];
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
              programs.umbriel = {
                enable = true;
                settings = ./home/umbriel/config.toml;
              };
              home.packages = with pkgs; [
                zenBrowser
                (claude-desktop-nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
                  postFixup = (old.postFixup or "") + ''
                    wrapProgram "$out/bin/claude-desktop" \
                      --add-flags "--password-store=gnome-libsecret"
                  '';
                }))
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
                STARSHIP_CONFIG = lib.mkForce "/home/janzon/.config/noctalia/starship.toml";
              };
              xdg.configFile."fish/functions/shell_welcome.fish".source = pkgs.replaceVars ./home/fish/shell_welcome.fish { figlet = pkgs.figlet; };
              xdg.configFile."fastfetch/shell.jsonc".source = ./home/fastfetch/shell.jsonc;
              programs.bat.enable = true;
              programs.fish = {
                enable = true;
                functions.fish_greeting.body = "printf '\\n'; shell_welcome; printf '\\n'";
                shellAliases = {
                  cat = "bat --style=plain --paging=never";
                  catn = "bat --style=numbers --paging=never";
                  t3pair = "t3 pair --base-dir /home/janzon/.t3/server";
                  ls = "eza --group-directories-first --icons=auto";
                  ll = "eza --long --header --group-directories-first --icons=auto";
                  la = "eza --all --group-directories-first --icons=auto";
                  lla = "eza --long --all --header --group-directories-first --icons=auto";
                  lt = "eza --tree --level=2 --group-directories-first --icons=auto";

                  # Common Oh My Zsh Git shortcuts, available in Fish.
                  g = "git";
                  gst = "git status";
                  gss = "git status --short";
                  gsb = "git status --short --branch";
                  ga = "git add";
                  gaa = "git add --all";
                  gapa = "git add --patch";
                  gau = "git add --update";
                  gd = "git diff";
                  gdca = "git diff --cached";
                  gds = "git diff --staged";
                  gdw = "git diff --word-diff";
                  gc = "git commit --verbose";
                  gcmsg = "git commit --message";
                  gcam = "git commit --all --message";
                  gcfu = "git commit --fixup";
                  gb = "git branch";
                  gba = "git branch --all";
                  gbd = "git branch --delete";
                  gco = "git checkout";
                  gcb = "git checkout -b";
                  gsw = "git switch";
                  gswc = "git switch --create";
                  gf = "git fetch";
                  gfo = "git fetch origin";
                  gl = "git pull";
                  gpr = "git pull --rebase";
                  gp = "git push";
                  gcl = "git clone --recurse-submodules";
                  glo = "git log --oneline --decorate";
                  glog = "git log --oneline --decorate --graph";
                  gloga = "git log --oneline --decorate --graph --all";
                  gm = "git merge";
                  grb = "git rebase";
                  grbi = "git rebase --interactive";
                  grbc = "git rebase --continue";
                  grba = "git rebase --abort";
                  gsta = "git stash push";
                  gstl = "git stash list";
                  gstp = "git stash pop";
                  gsts = "git stash show --patch";
                };
              };
              programs.starship = {
                enable = true;
                enableFishIntegration = true;
              };
              qt = {
                enable = true;
                platformTheme = {
                  name = "kde";
                  package = pkgs.kdePackages.plasma-integration;
                };
                style.package = darkly.packages.x86_64-linux.darkly-qt6;
              };
              gtk = {
                enable = true;
                iconTheme = {
                  name = "candy-icons";
                  package = pkgs.candy-icons;
                };
              };
              home.activation.dolphinColorScheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
                  --file "$HOME/.config/dolphinrc" \
                  --group UiSettings \
                  --key ColorScheme "*"
              '';
              # Enable every installed KIO thumbnailer; several are off by default.
              home.activation.dolphinPreviewPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
                  --file "$HOME/.config/dolphinrc" \
                  --group PreviewSettings \
                  --key Plugins "${lib.concatStringsSep "," [
                    "appimagethumbnail" "audiothumbnail" "blenderthumbnail" "comicbookthumbnail"
                    "cursorthumbnail" "directorythumbnail" "djvuthumbnail" "ebookthumbnail"
                    "exrthumbnail" "ffmpegthumbs" "gsthumbnail" "imagethumbnail" "jpegthumbnail"
                    "kraorathumbnail" "mobithumbnail" "opendocumentthumbnail" "pothumbnail"
                    "rawthumbnail" "svgthumbnail" "textthumbnail" "windowsexethumbnail"
                    "windowsimagethumbnail"
                  ]}"
              '';
              home.activation.kdeIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
                  --file "$HOME/.config/kdeglobals" \
                  --group Icons \
                  --key Theme "candy-icons"
              '';
              home.activation.starshipNoctaliaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                base="$HOME/.config/noctalia/starship-base.toml"
                palette="$HOME/.cache/noctalia/starship-palette.toml"
                target="$HOME/.config/noctalia/starship.toml"
                run ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$target")"
                if [ -f "$palette" ] && [ ! -v DRY_RUN ]; then
                  temporary="$(${pkgs.coreutils}/bin/mktemp "$(dirname "$target")/.starship.toml.XXXXXX")"
                  {
                    ${pkgs.gawk}/bin/awk '
                      $0 == "# >>> NOCTALIA STARSHIP PALETTE >>>" { skip = 1; next }
                      skip && $0 == "# <<< NOCTALIA STARSHIP PALETTE <<<" { skip = 0; next }
                      !skip { print }
                    ' "$base"
                    printf '\n# >>> NOCTALIA STARSHIP PALETTE >>>\n'
                    ${pkgs.coreutils}/bin/cat "$palette"
                    printf '# <<< NOCTALIA STARSHIP PALETTE <<<\n'
                  } >"$temporary"
                  if ! ${pkgs.diffutils}/bin/cmp -s "$temporary" "$target" 2>/dev/null; then
                    ${pkgs.coreutils}/bin/mv "$temporary" "$target"
                  else
                    ${pkgs.coreutils}/bin/rm "$temporary"
                  fi
                elif [ ! -f "$palette" ] && [ ! -e "$target" ]; then
                  run ${pkgs.coreutils}/bin/cp "$base" "$target"
                fi
              '';
              xdg.userDirs = {
                enable = true;
                createDirectories = true;
                projects = "/home/janzon/Projects";
              };
              xdg.mimeApps = {
                enable = true;
                defaultApplications = {
                  "application/vnd.flatpak" = [ "org.kde.discover.desktop" ];
                  "application/vnd.flatpak.ref" = [ "org.kde.discover.desktop" ];
                  "application/vnd.flatpak.repo" = [ "org.kde.discover.desktop" ];
                  "text/plain" = [ "dev.zed.Zed.desktop" ];
                  "application/xhtml+xml" = [ "helium.desktop" ];
                  "text/html" = [ "helium.desktop" ];
                  "text/xml" = [ "helium.desktop" ];
                  "x-scheme-handler/about" = [ "helium.desktop" ];
                  "x-scheme-handler/http" = [ "helium.desktop" ];
                  "x-scheme-handler/https" = [ "helium.desktop" ];
                  "image/avif" = [ "org.kde.gwenview.desktop" ];
                  "image/bmp" = [ "org.kde.gwenview.desktop" ];
                  "image/gif" = [ "org.kde.gwenview.desktop" ];
                  "image/heic" = [ "org.kde.gwenview.desktop" ];
                  "image/heif" = [ "org.kde.gwenview.desktop" ];
                  "image/jpeg" = [ "org.kde.gwenview.desktop" ];
                  "image/jxl" = [ "org.kde.gwenview.desktop" ];
                  "image/openraster" = [ "org.kde.gwenview.desktop" ];
                  "image/png" = [ "org.kde.gwenview.desktop" ];
                  "image/svg+xml" = [ "org.kde.gwenview.desktop" ];
                  "image/svg+xml-compressed" = [ "org.kde.gwenview.desktop" ];
                  "image/tiff" = [ "org.kde.gwenview.desktop" ];
                  "image/webp" = [ "org.kde.gwenview.desktop" ];
                  "image/x-eps" = [ "org.kde.gwenview.desktop" ];
                  "image/x-icns" = [ "org.kde.gwenview.desktop" ];
                  "image/x-ico" = [ "org.kde.gwenview.desktop" ];
                  "image/x-portable-bitmap" = [ "org.kde.gwenview.desktop" ];
                  "image/x-portable-graymap" = [ "org.kde.gwenview.desktop" ];
                  "image/x-portable-pixmap" = [ "org.kde.gwenview.desktop" ];
                  "image/x-psd" = [ "org.kde.gwenview.desktop" ];
                  "image/x-tga" = [ "org.kde.gwenview.desktop" ];
                  "image/x-webp" = [ "org.kde.gwenview.desktop" ];
                  "image/x-xbitmap" = [ "org.kde.gwenview.desktop" ];
                  "image/x-xcf" = [ "org.kde.gwenview.desktop" ];
                  "image/x-xpixmap" = [ "org.kde.gwenview.desktop" ];
                };
              };
              home.file.".local/share/applications/ut2004.desktop".text = ''
                [Desktop Entry]
                Type=Application
                Name=Unreal Tournament 2004
                Comment=Play Unreal Tournament 2004 with the OldUnreal patch
                TryExec=ut2004
                Exec=ut2004 -norunaway
                Icon=applications-games
                Terminal=false
                Categories=Game;ActionGame;
                StartupNotify=true
              '';
              xdg.configFile."nvim".source = ./home/nvim;
              xdg.configFile."ghostty/config.ghostty".source = ./home/ghostty/config.ghostty;
              xdg.configFile."noctalia/config.toml".source = ./home/noctalia/config.toml;
              xdg.configFile."noctalia/templates/zed.json".source = ./home/noctalia/templates/zed.json;
              xdg.configFile."noctalia/starship-base.toml".source = ./home/starship.toml;
              # Keep Vencord settings writable and let Noctalia generate its CSS.
              home.activation.discordNoctaliaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/Vencord/themes" "$HOME/.config/Vencord/settings"
                settings="$HOME/.config/Vencord/settings/settings.json"
                if [ ! -e "$settings" ]; then
                  run ${pkgs.coreutils}/bin/install -m 600 ${pkgs.writeText "vencord-noctalia-settings.json" (builtins.toJSON {
                    enabledThemes = [ "noctalia.theme.css" ];
                  })} "$settings"
                fi
              '';
              xdg.configFile."systemd/user/niri-overview-wallpaper.service.d/override.conf".source =
                ./home/systemd/niri-overview-wallpaper-override.conf;
              xdg.configFile."systemd/user/graphical-session.target.wants/vicinae.service".source =
                "${vicinae.packages.x86_64-linux.default}/share/systemd/user/vicinae.service";
              xdg.configFile."systemd/user/vicinae.service.d/override.conf".text = ''
                [Service]
                ExecStart=
                ExecStart=${vicinae.packages.x86_64-linux.default}/bin/vicinae server --replace
              '';
              xdg.configFile."niri/config.kdl".source = ./home/niri/config.kdl;
              xdg.configFile."xremap/config.yml".source = ./home/xremap/config.yml;
              home.file.".local/bin/reboot-windows" = {
                source = ./home/reboot-windows.py;
                executable = true;
              };
              home.file.".local/bin/niri-overview-wallpaper" = {
                source = ./home/dolphin/niri-overview-wallpaper;
                executable = true;
              };
              home.file.".local/bin/niri-caps-q" = {
                source = ./home/niri/caps-q-window;
                executable = true;
              };
              home.file.".local/bin/rcmd" = {
                source = rcmd;
                executable = true;
              };
              home.file.".local/bin/xremap-focus-or-launch" = {
                source = ./home/xremap/focus-or-launch;
                executable = true;
              };
              home.file.".local/bin/niri-focus-or-launch" = {
                source = ./home/niri/focus-or-launch;
                executable = true;
              };
              home.file.".local/bin/niri-background-apps-last" = {
                source = ./home/niri/background-apps-last;
                executable = true;
              };
              home.file.".local/bin/umbriel-scratchpad-hint" = {
                source = pkgs.replaceVars ./home/umbriel/scratchpad-hint {
                  inherit (pkgs) libnotify systemd;
                };
                executable = true;
              };
              home.file.".local/bin/umbriel-scratchpad-navigate" = {
                source = ./home/umbriel/scratchpad-navigate;
                executable = true;
              };
              home.file.".local/bin/umbriel-caps-q" = {
                source = ./home/umbriel/caps-q-window;
                executable = true;
              };
              home.file.".local/bin/umbriel-focus-or-launch" = {
                source = ./home/umbriel/focus-or-launch;
                executable = true;
              };
              home.file.".local/bin/umbriel-screenshot-window" = {
                source = ./home/umbriel/screenshot-window;
                executable = true;
              };
              home.file.".local/bin/umbriel-ambilight-session" = {
                source = ./home/umbriel/ambilight-session;
                executable = true;
              };
              home.file.".local/bin/umbriel-hdr-toggle" = {
                source = pkgs.writeShellScript "umbriel-hdr-toggle" ''
                  set -euo pipefail

                  output="DP-1"
                  hdr_active="$(umbriel outputs --json | jq -r --arg name "$output" '.[] | select(.name == $name) | .hdr_active')"
                  case "$hdr_active" in
                    true) hdr="off" ;;
                    false) hdr="on" ;;
                    *) exit 1 ;;
                  esac

                  runtime_dir="''${XDG_RUNTIME_DIR:?}"
                  display="''${WAYLAND_DISPLAY:-wayland-0}"
                  display="''${display//[^a-zA-Z0-9_.-]/_}"
                  profile="$runtime_dir/umbriel-hdr-$display.toml"
                  temporary="$profile.tmp.$$"
                  umask 077
                  trap 'rm -f "$temporary"' EXIT
                  cat > "$temporary" <<EOF
                  [include]
                  files = ["$HOME/.config/umbriel/config.toml"]

                  [output."$output"]
                  hdr = "$hdr"
                  EOF
                  mv "$temporary" "$profile"
                  trap - EXIT
                  exec umbriel config-replace "$profile"
                '';
                executable = true;
              };
              home.file.".local/bin/noctalia-bar-focus" = {
                source = pkgs.writeShellScript "noctalia-bar-focus" ''
                  set -euo pipefail

                  direction="''${1:-}"
                  case "$direction" in
                    left|right) ;;
                    *) exit 2 ;;
                  esac

                  if umbriel windows --json >/dev/null 2>&1; then
                    exec umbriel msg "window-focus-$direction"
                  else
                    exec niri msg action "focus-column-$direction"
                  fi
                '';
                executable = true;
              };
              home.file.".local/bin/noctalia-bar-autohide" = {
                source = ./home/noctalia/bar-autohide;
                executable = true;
              };
              home.file.".local/bin/niri-caps-q-quit" = {
                source = ./home/niri/caps-q-quit;
                executable = true;
              };
              home.file.".local/share/kio/servicemenus/set-niri-overview-wallpaper.desktop" = {
                source = ./home/dolphin/set-niri-overview-wallpaper.desktop;
                executable = true;
              };
            };
          }
        ];
      };
    };
}
