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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
  };

  # Dendritic layout: every .nix file under modules/ is a flake-parts module
  # (import-tree skips paths with a `_`-prefixed component). Files contribute
  # NixOS and Home Manager aspects to flake.modules.{nixos,homeManager}.*, and
  # modules/hosts/<name>/ builds nixosConfigurations.<name> from them.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
