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
    # niri = { enable = true; };             # second compositor next to Umbriel
    # torrentVpn = { enable = true; };       # qBittorrent only via Proton VPN
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
}
