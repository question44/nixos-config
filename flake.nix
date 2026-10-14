{
  description = "Minimal NixOS installation for moria";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, noctalia, helium, home-manager, ... }:
    {
      nixosConfigurations.moria = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/moria/default.nix
          noctalia.nixosModules.default
          helium.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.janzon = {
              home.stateVersion = "26.05";
              xdg.mimeApps = {
                enable = true;
                defaultApplications = {
                  "application/xhtml+xml" = [ "helium.desktop" ];
                  "text/html" = [ "helium.desktop" ];
                  "text/xml" = [ "helium.desktop" ];
                  "x-scheme-handler/about" = [ "helium.desktop" ];
                  "x-scheme-handler/http" = [ "helium.desktop" ];
                  "x-scheme-handler/https" = [ "helium.desktop" ];
                };
              };
              xdg.configFile."niri/config.kdl".source = ./home/niri/config.kdl;
            };
          }
        ];
      };
    };
}
