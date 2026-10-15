{ config, darkly, lib, pkgs, ... }:

let
  hyperhdr = pkgs.callPackage ../../packages/hyperhdr.nix { };
  aiUsagebar = pkgs.callPackage ../../packages/ai-usagebar.nix { };
  auroraNcs = pkgs.callPackage ../../packages/aurora-ncs.nix { };
  ut2004 = pkgs.callPackage ../../packages/ut2004.nix { };

  noctaliaPython = pkgs.symlinkJoin {
    name = "noctalia-plugin-python";
    paths = [ (pkgs.python3.withPackages (ps: [
      ps.pygobject3
      ps.pillow
      ps.psutil
      ps.speedtest-cli
      ps.syncedlyrics
    ])) ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/python3" \
        --prefix GI_TYPELIB_PATH : "${pkgs.gobject-introspection.out}/lib/girepository-1.0:${pkgs.at-spi2-core.out}/lib/girepository-1.0:${pkgs.gdk-pixbuf.out}/lib/girepository-1.0:${pkgs.pango.out}/lib/girepository-1.0:${pkgs.harfbuzz.out}/lib/girepository-1.0:${pkgs.gtk3.out}/lib/girepository-1.0:${pkgs.gtk-layer-shell.out}/lib/girepository-1.0" \
        --prefix LD_LIBRARY_PATH : "${pkgs.gtk3}/lib:${pkgs.gtk-layer-shell}/lib"
      if [ ! -e "$out/bin/python" ]; then
        ln -s python3 "$out/bin/python"
      fi
    '';
  };

  noctaliaPkgConfig = pkgs.writeShellScriptBin "pkg-config" ''
    export PKG_CONFIG_PATH="${pkgs.pipewire.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    exec ${pkgs.pkg-config}/bin/pkg-config "$@"
  '';

  spotifyLauncher = pkgs.writeShellScriptBin "spotify-launcher" ''
    exec ${pkgs.spotify}/bin/spotify "$@"
  '';

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

  t3codeStart = pkgs.writeShellScript "t3code-start" ''
    export PATH="/home/janzon/.local/bin:$PATH"
    exec /home/janzon/.local/bin/t3 serve --mode web --host 127.0.0.1 --port 3773 --base-dir /home/janzon/.t3/server
  '';

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
  networking.firewall.interfaces.enp4s0.allowedTCPPorts = [ 80 8080 ];
  services.tailscale.enable = true;
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl";

  users.defaultUserShell = pkgs.fish;
  users.groups.storage = { };
  users.users.janzon = {
    isNormalUser = true;
    description = "Janzon";
    shell = pkgs.fish;
    linger = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "storage" ];
  };

  programs.fish.enable = true;
  programs.nix-ld.enable = true;

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
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("storage") &&
          action.id == "org.freedesktop.udisks2.filesystem-mount-system") {
        return polkit.Result.YES;
      }
    });
  '';
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
  systemd.user.services.hyperhdr = {
    description = "HyperHDR ambient lighting with PipeWire screen capture";
    after = [
      "graphical-session.target"
      "pipewire.service"
      "wireplumber.service"
      "xdg-desktop-portal.service"
      "xdg-desktop-portal-gnome.service"
    ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    wants = [
      "pipewire.service"
      "wireplumber.service"
      "xdg-desktop-portal.service"
      "xdg-desktop-portal-gnome.service"
    ];
    serviceConfig = {
      ExecStart = "${hyperhdr}/bin/hyperhdr --pipewire --desktop";
      TimeoutStopSec = 5;
      KillMode = "mixed";
      Restart = "on-failure";
      RestartSec = 2;
      NoNewPrivileges = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
    };
  };
  systemd.user.services.xremap-restart = {
    description = "Restart xremap after keyboard connection";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart xremap.service";
    };
  };
  systemd.user.services.t3code = {
    description = "T3 Code web server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];
    environment = {
      HOME = "/home/janzon";
    };
    serviceConfig = {
      WorkingDirectory = "/home/janzon/Projects";
      ExecStart = t3codeStart;
      Restart = "on-failure";
      RestartSec = "10s";
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
    extraPortals = [ pkgs.oo7-portal pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
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

  services.caddy = {
    enable = true;
    extraConfig = ''
      :80 {
        root * ${../../home/services}
        file_server
      }

      :8080 {
        reverse_proxy 127.0.0.1:3773
      }
    '';
  };

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    oo7
    nodejs
    gh
    gnupg
    gnumake
    kdePackages.dolphin
    kdePackages.breeze
    candy-icons
    darkly.packages.${pkgs.system}.darkly-qt6
    spotify
    qt6Packages.qt6ct
    ghostty
    chromiumWithSecretService
    xwayland-satellite
    wl-clipboard
    wlr-randr
    pavucontrol
    tuigreet
    xremap
    hyperhdr
    aiUsagebar
    auroraNcs
    ut2004.ut2004
    ut2004.ut2004-import-rpm
    ut2004.ut2004-setup
    noctaliaPython
    spotifyLauncher
    cava
    jq
    playerctl
    spotify-player
    libnotify
    gtk3
    gtk-layer-shell
    xdg-utils
    bitwarden-cli
    hyprpicker
    mangowc
    efibootmgr
    grim
    kdePackages.kdeconnect-kde
    sshfs
    qrencode
    speedtest
    slurp
    tesseract
    imagemagick
    zbar
    translate-shell
    ffmpeg
    gpu-screen-recorder
    wl-screenrec
    wf-recorder
    bc
    pulseaudio
    mpv
    noctaliaPkgConfig
    pipewire.dev
    sway
  ];

  programs.dconf.enable = true;
  services.xserver.enable = false;

  system.stateVersion = "26.05";
}
