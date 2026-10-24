{ config, pkgs, ... }:
{
  # Only this fixed operation can write the GRUB one-time selection.
  systemd.services.dashboard-reboot-windows = {
    description = "Reboot once into the existing Windows GRUB entry";
    path = [ pkgs.grub2_efi pkgs.util-linux pkgs.coreutils pkgs.systemd ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${./dashboard-control/reboot_windows.py}";
      TimeoutStartSec = 60;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/boot/grub/grubenv" ];
      RestrictAddressFamilies = [ "AF_UNIX" ];
      CapabilityBoundingSet = "";
      UMask = "0077";
    };
  };
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "janzon" &&
          action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "dashboard-reboot-windows.service" &&
          action.lookup("verb") == "start") {
        return polkit.Result.YES;
      }
    });
  '';

  systemd.user.services.dashboard-control = {
    description = "Local Caddy dashboard controls";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "janzon";
    environment.DASHBOARD_WLED_URL = "http://192.168.1.118";
    path = [ pkgs.systemd pkgs.wlopm pkgs.niri config.programs.umbriel.package
      config.programs.mango.package ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${./dashboard-control/control.py}";
      Restart = "on-failure";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" ];
      LockPersonality = true;
      UMask = "0077";
    };
  };
}
