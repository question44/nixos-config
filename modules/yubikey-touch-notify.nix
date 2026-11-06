{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.my.yubikey.enable {
  # pam-u2f already emits open/close events on this file while awaiting touch.
  # Keep the notifier in the user's session; it does not participate in PAM.
  systemd.user.services.yubikey-touch-notify = {
    description = "YubiKey touch notification and sound";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.libnotify pkgs.glib pkgs.pipewire ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -u ${./yubikey-touch-notify.py} ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-information.oga";
      Restart = "on-failure";
      RestartSec = 2;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
    };
  };
  };
}
