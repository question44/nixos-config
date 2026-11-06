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

  outputs = { self, nixpkgs, claude-desktop-nix, moonshine, monstar, dashboard, noctalia, noctalia-greeter, umbriel, millennium, helium, zen-browser, darkly, vicinae, home-manager, ... }:
    let
      # Each host is hosts/<name>: hardware plus my.* settings (modules/my.nix).
      mkHost = name: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit darkly vicinae; };
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
            systemd.services."home-manager-${config.my.user}".environment.NIX_CONFIG =
              "experimental-features = nix-command flakes";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit umbriel monstar claude-desktop-nix zen-browser darkly vicinae;
            };
            home-manager.users.${config.my.user} = import ./home/janzon;
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
    };
}
