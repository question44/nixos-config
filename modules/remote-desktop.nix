{ config, lib, pkgs, ... }:

let
  desktopPackages = with pkgs; [
    xfce4-session xfce4-panel xfdesktop xfwm4 xfce4-settings
    xfce4-appfinder xfce4-terminal thunar adwaita-icon-theme
  ];
  session = pkgs.writeShellScript "remote-desktop-session" ''
    # Keep the remote X11 session separate from the local Wayland session bus.
    unset DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY UMBRIEL_SOCKET
    unset NIRI_SOCKET MANGO_INSTANCE_SIGNATURE SESSION_MANAGER NIXOS_OZONE_WL
    export XDG_SESSION_TYPE=x11
    export XDG_CURRENT_DESKTOP=XFCE
    export XDG_SESSION_DESKTOP=xfce
    export QT_QPA_PLATFORM=xcb
    export GDK_BACKEND=x11
    export MOZ_ENABLE_WAYLAND=0
    export PATH=${lib.makeBinPath desktopPackages}:$PATH
    exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.xfce4-session}/bin/xfce4-session
  '';
in
{
  environment.systemPackages = desktopPackages;
  environment.pathsToLink = [ "/share/xfce4" ];
  programs.xfconf.enable = true;

  services.xrdp = {
    enable = true;
    openFirewall = false;
    defaultWindowManager = "${session}";
    extraConfDirCommands = ''
      substituteInPlace $out/sesman.ini \
        --replace-fail 'AllowRootLogin=true' 'AllowRootLogin=false'
    '';
  };
  security.pam.services.xrdp-sesman.allowNullPassword = lib.mkForce false;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.xrdp.port ];
}
