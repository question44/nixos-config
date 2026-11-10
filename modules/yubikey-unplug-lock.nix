# Lock every session when the YubiKey is unplugged. udev only starts a oneshot;
# the oneshot waits two seconds and does nothing if a YubiKey (vendor 1050) is
# present again, so a mode switch or re-enumeration does not lock. Noctalia
# locks on logind's Lock signal and ignores it while already locked. Unlocking
# still accepts the password and fingerprint, so a missing key cannot lock
# anyone out.
{
  flake.modules.nixos.yubikey-unplug-lock =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.yubikey;
    in
    {
      config = lib.mkIf (cfg.enable && cfg.lockOnRemoval) {
        services.udev.extraRules = ''
          ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="1050/*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start yubikey-unplug-lock.service"
        '';

        systemd.services.yubikey-unplug-lock = {
          description = "Lock sessions after the YubiKey is unplugged";
          path = [
            pkgs.coreutils
            pkgs.systemd
          ];
          script = ''
            sleep 2
            for vendor in /sys/bus/usb/devices/*/idVendor; do
              if [ "$(cat "$vendor" 2>/dev/null)" = 1050 ]; then
                echo "A YubiKey is present again; not locking."
                exit 0
              fi
            done
            echo "YubiKey unplugged; locking all sessions."
            loginctl lock-sessions
          '';
          serviceConfig.Type = "oneshot";
        };
      };
    };
}
