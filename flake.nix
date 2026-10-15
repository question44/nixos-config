{
  description = "Minimal NixOS installation for moria";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darkly = {
      url = "github:Bali10050/Darkly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, noctalia, helium, darkly, home-manager, ... }:
    {
      nixosConfigurations.moria = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit darkly; };
        modules = [
          ./hosts/moria/default.nix
          noctalia.nixosModules.default
          helium.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.janzon = { lib, pkgs, ... }:
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
              home.stateVersion = "26.05";
              home.packages = with pkgs; [
                zed-editor
                neovim
                fd
                ripgrep
                git
                curl
                lazygit
                gcc
                tree-sitter
                nodejs
              ];
              home.sessionVariables = {
                EDITOR = "${sessionEditor}/bin/session-editor";
                VISUAL = "${sessionEditor}/bin/session-editor";
                GIT_EDITOR = "${sessionEditor}/bin/session-editor";
              };
              programs.fish = {
                enable = true;
                shellAliases.t3pair = "t3 pair --base-dir /home/janzon/.t3/server";
              };
              programs.starship = {
                enable = true;
                enableFishIntegration = true;
                settings = builtins.fromTOML (builtins.readFile ./home/starship.toml);
              };
              qt = {
                enable = true;
                style.package = darkly.packages.x86_64-linux.darkly-qt6;
                qt6ctSettings = {
                  Appearance = {
                    style = "Darkly";
                    custom_palette = true;
                    color_scheme_path = "/home/janzon/.config/qt6ct/colors/noctalia.conf";
                    standard_dialogs = "default";
                  };
                };
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
                };
              };
              home.file.".local/share/applications/ut2004.desktop".text = ''
                [Desktop Entry]
                Type=Application
                Name=Unreal Tournament 2004
                Comment=Play Unreal Tournament 2004 with the OldUnreal patch
                TryExec=ut2004
                Exec=ut2004
                Icon=applications-games
                Terminal=false
                Categories=Game;ActionGame;
                StartupNotify=true
              '';
              xdg.configFile."nvim".source = ./home/nvim;
              xdg.configFile."noctalia/config.toml".source = ./home/noctalia/config.toml;
              xdg.configFile."niri/config.kdl".source = ./home/niri/config.kdl;
              xdg.configFile."xremap/config.yml".source = ./home/xremap/config.yml;
            };
          }
        ];
      };
    };
}
