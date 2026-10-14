{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-kernel-modules"
      "nvidia-settings"
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "moria";
  networking.networkmanager.enable = true;
  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.janzon = {
    isNormalUser = true;
    description = "Janzon";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
  };

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  services.dbus.enable = true;
  services.gnome.gnome-keyring.enable = false;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.niri}/bin/niri-session";
        user = "greeter";
      };
    };
  };

  systemd.user.services.niri.enableDefaultPath = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    configPackages = [ pkgs.niri ];
    config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "gnome";
  };

  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  environment.systemPackages = with pkgs; [
    oo7
    ghostty
    ungoogled-chromium
    xwayland-satellite
    wl-clipboard
    pavucontrol
    tuigreet
  ];

  programs.dconf.enable = true;
  services.xserver.enable = false;

  system.stateVersion = "26.05";
}
