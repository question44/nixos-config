{ config, pkgs, ... }:
{
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
