# mac-vm: an aarch64 VMware Fusion guest on the MacBook (Apple Silicon) running
# the shared desktop without erebor's hardware or services. Every optional
# my.* feature stays off; x86-only apps are dropped by the shared aspects on
# aarch64. Install steps: docs/mac-vm.md.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.nixosConfigurations.mac-vm = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [ nixos.mac-vm ];
  };

  flake.modules.nixos.mac-vm =
    { ... }:

    {
      imports = with nixos; [
        ./_hardware-configuration.nix
        workstation
      ];

      networking.hostName = "mac-vm";

      my = {
        user = {
          name = "janzon";
          description = "Janzon";
        };
        network = {
          domain = "mac-vm.localdomain";
          # Fusion's virtual vmxnet3 NIC on Apple Silicon.
          lanInterface = "ens160";
        };
      };

      # open-vm-tools: display resizing, time sync, clean shutdown.
      virtualisation.vmware.guest.enable = true;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      system.stateVersion = "26.05";
    };
}
