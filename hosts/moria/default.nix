{ config, darkly, lib, pkgs, ... }:

let
  oo7Pam = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "oo7-pam";
    inherit (pkgs.oo7) version src cargoDeps;
    sourceRoot = "${finalAttrs.src.name}/pam";
    cargoRoot = "../";

    nativeBuildInputs = with pkgs; [
      pkg-config
      meson
      ninja
      rustPlatform.cargoSetupHook
      rustc
      cargo
    ];
    buildInputs = [ pkgs.systemdLibs ];
  });

  chromiumWithSecretService = pkgs.symlinkJoin {
    name = "ungoogled-chromium-with-secret-service";
    paths = [ pkgs.ungoogled-chromium ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/chromium" "$out/bin/chromium-browser"
      makeWrapper ${pkgs.ungoogled-chromium}/bin/chromium "$out/bin/chromium" \
        --add-flags "--password-store=gnome-libsecret"
      makeWrapper ${pkgs.ungoogled-chromium}/bin/chromium-browser "$out/bin/chromium-browser" \
        --add-flags "--password-store=gnome-libsecret"
    '';
  };
in

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
      "spotify"
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernelModules = [ "uinput" ];

  networking.hostName = "moria";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.tailscale.enable = true;
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl";

  users.defaultUserShell = pkgs.fish;
  users.users.janzon = {
    isNormalUser = true;
    description = "Janzon";
    shell = pkgs.fish;
    linger = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
  };

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = true;
  security.sudo.extraRules = [
    {
      users = [ "janzon" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  security.polkit.enable = true;
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", TAG+="uaccess"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="320f", ATTR{idProduct}=="5055", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="xremap-restart.service"
  '';

  systemd.user.services.xremap = {
    description = "xremap key remapper";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xremap}/bin/xremap --mouse --device \"Telink IQUNIX 2.4GHz\" --device \"RDR IQUNIX MQ80 KB\" --device \"Logitech G502 X LS\" /home/janzon/.config/xremap/config.yml";
      Restart = "on-failure";
    };
  };
  systemd.user.services.xremap-restart = {
    description = "Restart xremap after keyboard connection";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart xremap.service";
    };
  };

  security.pam.services.greetd.rules.auth.unix_early = {
    order = config.security.pam.services.greetd.rules.auth.unix.order - 20;
    control = "optional";
    modulePath = "${pkgs.linux-pam}/lib/security/pam_unix.so";
    settings = {
      likeauth = true;
      nullok = true;
    };
  };
  security.pam.services.greetd.rules.auth.oo7 = {
    order = config.security.pam.services.greetd.rules.auth.unix_early.order + 10;
    control = "optional";
    modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
  };
  security.pam.services.greetd.rules.session.oo7 = {
    order = config.security.pam.services.greetd.rules.session.systemd.order + 10;
    control = "optional";
    modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
    settings.auto_start = true;
  };

  services.dbus.enable = true;
  services.openssh.enable = true;
  services.udisks2.enable = true;
  services.dbus.packages = [ pkgs.oo7-server ];
  services.gnome.gnome-keyring.enable = false;

  systemd.packages = [ pkgs.oo7-server pkgs.oo7-portal ];
  systemd.user.services.oo7-daemon = {
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = lib.mkForce [ "" "/run/wrappers/bin/oo7-daemon" ];
  };

  security.wrappers.oo7-daemon = {
    owner = "root";
    group = "root";
    capabilities = "cap_ipc_lock=ep";
    source = "${pkgs.oo7-server}/libexec/oo7-daemon";
  };
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
    extraPortals = [ pkgs.oo7-portal pkgs.xdg-desktop-portal-gtk ];
    configPackages = [ pkgs.niri ];
    config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "oo7";
  };

  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    recommendedServices.enable = true;
  };

  programs.helium = {
    enable = true;
    flags = [ "--password-store=gnome-libsecret" ];
  };

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    oo7
    gh
    kdePackages.dolphin
    kdePackages.breeze
    darkly.packages.${pkgs.system}.darkly-qt6
    spotify
    qt6Packages.qt6ct
    ghostty
    chromiumWithSecretService
    xwayland-satellite
    wl-clipboard
    pavucontrol
    tuigreet
    xremap
  ];

  programs.dconf.enable = true;
  services.xserver.enable = false;

  system.stateVersion = "26.05";
}
