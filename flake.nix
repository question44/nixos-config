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
            home-manager.users.janzon = { pkgs, ... }: {
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
                EDITOR = "zeditor --wait";
                VISUAL = "zeditor --wait";
                GIT_EDITOR = "zeditor --wait";
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
                    color_scheme_path = "/home/janzon/.config/qt6ct/colors/Darkly.conf";
                    standard_dialogs = "default";
                  };
                };
              };
              xdg.configFile."qt6ct/colors/Darkly.conf".source = ./home/qt6ct/Darkly.conf;
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
              xdg.configFile."nvim".source = ./home/nvim;
              xdg.configFile."niri/config.kdl".source = ./home/niri/config.kdl;
              xdg.configFile."xremap/config.yml".source = ./home/xremap/config.yml;
            };
          }
        ];
      };
    };
}
