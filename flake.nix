{
  description = "Minimal NixOS installation for moria";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    umbriel.url = "github:noctalia-dev/umbriel";
    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
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

  outputs = { self, nixpkgs, noctalia, umbriel, millennium, helium, darkly, vicinae, home-manager, ... }:
    {
      nixosConfigurations.moria = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit darkly vicinae; };
        modules = [
          ./hosts/moria/default.nix
          noctalia.nixosModules.default
          umbriel.nixosModules.default
          helium.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ millennium.overlays.default ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.janzon = { lib, pkgs, ... }:
              let
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
              programs.umbriel = {
                enable = true;
                settings = ./home/umbriel/config.toml;
              };
              home.packages = with pkgs; [
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
                jq
                tree-sitter
                nodejs
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
                $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
                  --file "$HOME/.config/dolphinrc" \
                  --group UiSettings \
                  --key ColorScheme "*"
              '';
              home.activation.kdeIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
                  --file "$HOME/.config/kdeglobals" \
                  --group Icons \
                  --key Theme "candy-icons"
              '';
              home.activation.nomacsSystemTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
                  --file "$HOME/.config/nomacs/Image Lounge.conf" \
                  --group General \
                  --key themeName312 "System Theme"
              '';
              home.activation.starshipNoctaliaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                base="$HOME/.config/noctalia/starship-base.toml"
                palette="$HOME/.cache/noctalia/starship-palette.toml"
                target="$HOME/.config/noctalia/starship.toml"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$target")"
                if [ -f "$palette" ]; then
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
                    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$temporary" "$target"
                  else
                    ${pkgs.coreutils}/bin/rm "$temporary"
                  fi
                elif [ ! -e "$target" ]; then
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp "$base" "$target"
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
                  "text/plain" = [ "dev.zed.Zed.desktop" ];
                  "application/xhtml+xml" = [ "helium.desktop" ];
                  "text/html" = [ "helium.desktop" ];
                  "text/xml" = [ "helium.desktop" ];
                  "x-scheme-handler/about" = [ "helium.desktop" ];
                  "x-scheme-handler/http" = [ "helium.desktop" ];
                  "x-scheme-handler/https" = [ "helium.desktop" ];
                  "image/avif" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/bmp" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/gif" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/heic" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/heif" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/jpeg" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/jxl" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/png" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/tiff" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/webp" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-eps" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-ico" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-portable-bitmap" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-portable-graymap" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-portable-pixmap" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-xbitmap" = [ "org.nomacs.ImageLounge.desktop" ];
                  "image/x-xpixmap" = [ "org.nomacs.ImageLounge.desktop" ];
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
              xdg.configFile."noctalia/starship-base.toml".source = ./home/starship.toml;
              # Keep Vencord settings writable and let Noctalia generate its CSS.
              home.activation.discordNoctaliaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/Vencord/themes" "$HOME/.config/Vencord/settings"
                settings="$HOME/.config/Vencord/settings/settings.json"
                if [ ! -e "$settings" ]; then
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${pkgs.writeText "vencord-noctalia-settings.json" (builtins.toJSON {
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
              home.file.".local/bin/umbriel-caps-q" = {
                source = ./home/umbriel/caps-q-window;
                executable = true;
              };
              home.file.".local/bin/umbriel-focus-or-launch" = {
                source = ./home/umbriel/focus-or-launch;
                executable = true;
              };
              home.file.".local/bin/umbriel-background-apps-last" = {
                source = ./home/umbriel/background-apps-last;
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
