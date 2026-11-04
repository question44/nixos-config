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

  services.erebor-dashboard = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ../home/dashboard-settings.json);
    control = {
      enable = true;
      user = "janzon";
      allowedHosts = [ "erebor" "localhost" "127.0.0.1" "erebor.local" "erebor.jzon.pl" ];
      enabledActions = [ "display-on" "display-off" "screen-dp" "screen-hdmi" "ambilight-on" "ambilight-off"
        "sleep" "power-off" "reboot-windows" ];
      wledUrl = "http://192.168.1.118";
      # The same helper backs the Noctalia bar's screen switch.
      extraPackages = [ pkgs.niri config.programs.umbriel.package
        (pkgs.callPackage ../packages/umbriel-display-mode.nix { }) ];
    };
  };
}
