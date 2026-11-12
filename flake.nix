{
  description = "Minimal NixOS installation for erebor";

  # Third-party inputs are pinned to a commit, so `nix flake update` moves only
  # nixpkgs and home-manager. Bump a pin deliberately: change its revision,
  # review the upstream changes, then build and erebor-diff
  # (scripts/erebor-update-branch --pinned does this for all of them).
  inputs = {
    self.submodules = true;
    dashboard = {
      url = "path:./apps/erebor-dashboard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Chomik, the Chomikuj.pl client (apps/chomik-qml submodule).
    chomik = {
      url = "path:./apps/chomik-qml";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Vitrum, the liquid glass demo for umbriel_glass_v1 (apps/vitrum submodule).
    vitrum = {
      url = "path:./apps/vitrum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonshine = {
      url = "github:hgaiser/moonshine/79554f853135cbac44502b58093a4eb0f0f5e6f1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    strata = {
      url = "github:lgse/strata/491e6ba9735e821f9f49910ffd2582076196865c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    monstar.url = "github:rockorager/monstar/406c48eb938a065997bf5378457d7ca24fbfcea5";
    claude-desktop-nix.url = "github:tomsch/claude-desktop-nix/b16f4856da3a0b218d3ed0722df26b452039079f";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    noctalia.url = "github:noctalia-dev/noctalia-shell/f90f230f8116eff55e4e96a7a97756c2b00b7ac2";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter/effcb9ffc33f7120cbc6cfc6c6527e9da763a0e9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umbriel.url = "github:noctalia-dev/umbriel/c6ad18d5ed7e3f928e546e24a4a17719e0522ff6";
    millennium = {
      url = "github:SteamClientHomebrew/Millennium/d6a7822a43744b6290a0e059bdd032d9b9a2ec94?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake/532b9a848c6b96d9f607e8856d1a458bdb7dcf66";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser/9fe3f8f48c8c25b0d245d13d6c91d4cf77adc729";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darkly = {
      url = "github:Bali10050/Darkly/3f69ff222e3ad7dcb901a41be691020f70112ea6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Follows nixpkgs so Vicinae uses the system's Qt, not a second copy.
    vicinae = {
      url = "github:vicinaehq/vicinae/0ed7dcce1f530067aa251d1beab1a57760e385b4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts/ea2630b7470978622c7689a1ff75d2b389175399";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix/89a234ce2daf6e568a7d4b4fe250afdd23d84e20";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/ff0e21a414d4547183396da1b44a66f2577b65e9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree/eb1b52eaecc57f7c136d07ae8a93e724dfecac46";
  };

  # Dendritic layout: every .nix file under modules/ is a flake-parts module
  # (import-tree skips paths with a `_`-prefixed component). Files contribute
  # NixOS and Home Manager aspects to flake.modules.{nixos,homeManager}.*, and
  # modules/hosts/<name>/ builds nixosConfigurations.<name> from them.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
