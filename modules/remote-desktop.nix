# xrdp over Tailscale with an LXQt X11 session. LXQt is Qt-based, so it reuses
# the Qt/KDE libraries already installed for Dolphin, Okular and Gwenview.
# Its packages stay out of the system profile (and the Wayland app menu): the
# session script puts them on its own PATH and XDG paths.
{
  flake.modules.nixos.remote-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      lxqt = pkgs.symlinkJoin {
        name = "remote-desktop-lxqt";
        paths =
          (with pkgs; [
            kdePackages.kwindowsystem
            kdePackages.libkscreen
            kdePackages.qtsvg
            kdePackages.breeze-icons
            libfm
            libfm-extra
            menu-cache
            openbox
          ])
          ++ (with pkgs.lxqt; [
            libfm-qt
            lxqt-about
            lxqt-config
            lxqt-globalkeys
            lxqt-menu-data
            lxqt-notificationd
            lxqt-policykit
            lxqt-qtplugin
            lxqt-session
            lxqt-themes
            lxqt-panel
            lxqt-runner
            pcmanfm-qt
            pavucontrol-qt
            qterminal
          ]);
      };
      session = pkgs.writeShellScript "remote-desktop-session" ''
        # Keep the remote X11 session separate from the local Wayland session bus.
        unset DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY UMBRIEL_SOCKET
        unset SESSION_MANAGER NIXOS_OZONE_WL QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE
        export XDG_SESSION_TYPE=x11
        export XDG_CURRENT_DESKTOP=LXQt
        export XDG_SESSION_DESKTOP=lxqt
        export XDG_MENU_PREFIX=lxqt-
        export QT_QPA_PLATFORM=xcb
        export GDK_BACKEND=x11
        export MOZ_ENABLE_WAYLAND=0
        export PATH=${lxqt}/bin:$PATH
        # LXQt ships its default configs under share/lxqt rather than etc/xdg.
        export XDG_CONFIG_DIRS=${lxqt}/etc/xdg:${lxqt}/share''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}
        export XDG_DATA_DIRS=${lxqt}/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export QT_PLUGIN_PATH=${lxqt}/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
        exec ${pkgs.dbus}/bin/dbus-run-session -- ${lxqt}/bin/startlxqt
      '';
    in
    {
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
    };
}
