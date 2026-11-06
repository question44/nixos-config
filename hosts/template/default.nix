# Starting point for another erebor-like machine. Copy this folder to
# hosts/<name>, replace hardware-configuration.nix with the new machine's
# (nixos-generate-config), adjust the values below, and add the host to
# nixosConfigurations in flake.nix.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/workstation
    # Optional hardware-specific modules used by erebor:
    # ../../modules/xremap.nix          # set my.xremap.devices
    # ../../modules/nvidia.nix
    # ../../modules/windows-vm.nix
    # ../../modules/looking-glass.nix
  ];

  networking.hostName = "template";

  my = {
    user = {
      name = "janzon";
      description = "Janzon";
    };
    network = {
      domain = "template.example.com";
      lanInterface = "enp1s0";
    };
    # Everything below defaults to off; enable what this machine has.
    # ambilight = {
    #   enable = true;
    #   musicSink = "alsa_output.…";
    #   wledUrl = "http://192.168.1.x";
    # };
    # yubikey = { enable = true; };
    # macApproval = { enable = true; };
    # nanokvm = { enable = true; url = "https://<kvm-name>:8443"; };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.05";
}
