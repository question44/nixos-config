{ config, lib, pkgs, ... }:
let
  mango = config.programs.mango.package;
  session = pkgs.writeShellScript "mango-session" ''
    export XDG_CURRENT_DESKTOP=mango
    export XDG_SESSION_DESKTOP=mango
    export XDG_SESSION_TYPE=wayland
    export QT_QPA_PLATFORMTHEME=kde
    trap '${pkgs.systemd}/bin/systemctl --user stop mango-session.target graphical-session.target' EXIT
    ${mango}/bin/mango "$@"
  '';
  sessionEntry = pkgs.runCommand "mango-session-entry" {
    passthru.providedSessions = [ "mango" ];
  } ''
    mkdir -p $out/share/wayland-sessions
    cp ${mango}/share/wayland-sessions/mango.desktop $out/share/wayland-sessions/mango.desktop
    substituteInPlace $out/share/wayland-sessions/mango.desktop \
      --replace-fail 'Exec=mango' 'Exec=${session}'
  '';
in {
  programs.mango = {
    enable = true;
    addLoginEntry = false;
  };
  services.displayManager.sessionPackages = [ sessionEntry ];
  # Mango itself starts graphical-session.target before config autostart. Gate
  # Noctalia here so its first output enumeration includes the wallpaper output.
  systemd.user.services.noctalia.serviceConfig.ExecStartPre =
    pkgs.writeShellScript "mango-ambilight-before-noctalia" ''
      if [ "''${XDG_CURRENT_DESKTOP:-}" = mango ]; then
        if ! ${mango}/bin/mmsg get all-monitors | ${pkgs.jq}/bin/jq -e \
          '.monitors[] | select(.name == "ambilight")' >/dev/null; then
          ${mango}/bin/mmsg dispatch create_virtual_output,ambilight
        fi
      fi
    '';
  xdg.portal.config.mango."org.freedesktop.impl.portal.Secret" = lib.mkForce [ "oo7" ];
}
