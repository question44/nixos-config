# Starting point for another erebor-like machine. Copy this folder to
# modules/hosts/<name>, replace _hardware-configuration.nix with the new
# machine's (nixos-generate-config), rename `template` below to the host's
# name, and adjust the values. import-tree picks the new host up by itself.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  # Evaluated, never deployed: proves the optional features switch off.
  flake.nixosConfigurations.template = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ nixos.template ];
  };

  flake.modules.nixos.template =
    { ... }:

    {
      imports = with nixos; [
        ./_hardware-configuration.nix
        workstation
        # Optional hardware-specific aspects used by erebor:
        # xremap          # set my.xremap.devices
        # nvidia
        # windows-vm
        # looking-glass
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
        # torrentVpn = { enable = true; };       # qBittorrent only via Proton VPN
        # updateBranch = { enable = true; };     # weekly tested flake update branch
        # streaming = {
        #   sunshine.enable = true;              # also serves sunshine.<domain>
        #   moonshine.enable = true;
        # };
        # Web services: each adds its routes, /etc/hosts name and LAN port
        # (see modules/services and my.services in modules/my.nix).
        # services = {
        #   jellyfin.enable = true;
        #   nextcloud.enable = true;
        #   syncthing.enable = true;
        #   qbittorrent.enable = true;
        #   ollama.enable = true;                # needs an NVIDIA GPU
        #   t3code.enable = true;
        #   cockpit.enable = true;
        # };
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      system.stateVersion = "26.05";
    };
}
