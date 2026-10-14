{
  description = "Minimal NixOS installation for moria";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
  };

  outputs = { self, nixpkgs, noctalia, ... }:
    {
      nixosConfigurations.moria = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/moria/default.nix
          noctalia.nixosModules.default
        ];
      };
    };
}
