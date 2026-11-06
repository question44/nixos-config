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
    monstar.url = "github:rockorager/monstar/406c48eb938a065997bf5378457d7ca24fbfcea5";
    claude-desktop-nix.url = "github:tomsch/claude-desktop-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    # Follows nixpkgs so Vicinae uses the system's Qt, not a second copy.
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      claude-desktop-nix,
      moonshine,
      monstar,
      dashboard,
      noctalia,
      noctalia-greeter,
      umbriel,
      millennium,
      helium,
      zen-browser,
      darkly,
      vicinae,
      home-manager,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      inherit (pkgs) lib;
      # Every .nix file the repo formats; the dashboard submodule is its own repo.
      nixFiles = lib.fileset.difference (lib.fileset.fileFilter (f: f.hasExt "nix") ./.) ./apps;
      # Each host is hosts/<name>: hardware plus my.* settings (modules/my.nix).
      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              darkly
              vicinae
              monstar
              claude-desktop-nix
              zen-browser
              ;
          };
          modules = [
            moonshine.nixosModules.default
            ./modules/moonshine.nix
            (./hosts + "/${name}")
            noctalia-greeter.nixosModules.default
            noctalia.nixosModules.default
            umbriel.nixosModules.default
            dashboard.nixosModules.default
            ./modules/dashboard-control.nix
            helium.nixosModules.default
            # Privileged input-server wrapper for vicinae paste and snippets.
            vicinae.nixosModules.default
            home-manager.nixosModules.home-manager
            ({ config, ... }: {
              nixpkgs.overlays = [ millennium.overlays.default ];
              # Home Manager uses the modern profile CLI during system activation.
              systemd.services."home-manager-${config.my.user.name}".environment.NIX_CONFIG =
                "experimental-features = nix-command flakes";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit
                  umbriel
                  darkly
                  vicinae
                  ;
              };
              home-manager.users.${config.my.user.name} = import ./home/janzon;
            })
          ];
        };
    in
    {
      nixosConfigurations = {
        erebor = mkHost "erebor";
        # Evaluated, never deployed: proves the optional features switch off.
        template = mkHost "template";
      };

      # `nix fmt` formats the whole repo, or only the files given.
      formatter.x86_64-linux = pkgs.writeShellScriptBin "erebor-fmt" ''
        if [ "$#" -eq 0 ]; then
          cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
          ${pkgs.git}/bin/git ls-files -z -- '*.nix' ':!:apps/**' \
            | ${pkgs.findutils}/bin/xargs -0 ${pkgs.nixfmt}/bin/nixfmt
        else
          exec ${pkgs.nixfmt}/bin/nixfmt "$@"
        fi
      '';

      # Rebuilds only when a .nix file changes.
      checks.x86_64-linux.format =
        pkgs.runCommand "erebor-format-check"
          {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = nixFiles;
            };
          }
          ''
            cd "$src"
            find . -name '*.nix' -print0 | xargs -0 ${pkgs.nixfmt}/bin/nixfmt --check
            touch "$out"
          '';
    };
}
