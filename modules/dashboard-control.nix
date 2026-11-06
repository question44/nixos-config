{ config, lib, pkgs, ... }:
let
  user = config.my.user.name;
  domain = config.my.network.domain;
  my = config.my;
  ambilightActions = [ "ambilight-on" "ambilight-off" ];
  # Drop buttons for hardware this machine does not have.
  keepAction = a:
    (my.ambilight.enable || !(lib.elem a ambilightActions))
    && (my.nanokvm.enable || a != "wake");
  baseSettings = builtins.fromJSON (builtins.readFile ../home/dashboard-settings.json);
in
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
      if (subject.user == "${user}" &&
          action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "dashboard-reboot-windows.service" &&
          action.lookup("verb") == "start") {
        return polkit.Result.YES;
      }
      // The dashboard API runs outside an active session, which the default policy requires.
      if (subject.user == "${user}" &&
          action.id == "org.freedesktop.UPower.PowerProfiles.switch-profile") {
        return polkit.Result.YES;
      }
    });
  '';

  services.erebor-dashboard = {
    enable = true;
    settings = baseSettings // {
      actions = lib.filter keepAction baseSettings.actions;
    } // lib.optionalAttrs my.nanokvm.enable {
      wakeUrl = "${my.nanokvm.url}/wake";
      outletUrl = "${my.nanokvm.url}/outlet";
    };
    control = {
      enable = true;
      user = "${user}";
      allowedHosts = [ "${config.networking.hostName}" "localhost" "127.0.0.1" "${config.networking.hostName}.local" "${domain}" ];
      enabledActions = lib.filter keepAction [ "display-on" "display-off" "screen-dp" "screen-hdmi" "ambilight-on" "ambilight-off"
        "profile-performance" "profile-balanced" "profile-power-saver"
        "sleep" "power-off" "reboot-windows" "moonshine-pair" ];
      wledUrl = lib.mkIf (my.ambilight.enable && my.ambilight.wledUrl != null) my.ambilight.wledUrl;
      # The same helper backs the Noctalia bar's screen switch.
      extraPackages = [ pkgs.niri config.programs.umbriel.package
        (pkgs.callPackage ../packages/umbriel-display-mode.nix { }) ];
    };
  };
}
