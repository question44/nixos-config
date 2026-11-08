# Oo7 Secret Service: daemon, portal and login PAM unlock.
{
  flake.modules.nixos.keyring =
    { lib, ... }:
    {
      # Daemon, portal, cap_ipc_lock wrapper and pam_oo7 on the login stack,
      # which greetd includes.
      services.oo7.enable = true;
      services.gnome.gnome-keyring.enable = false;

      # The module adds the wrapper but the packaged unit runs the plain binary.
      systemd.user.services.oo7-daemon.serviceConfig.ExecStart = lib.mkForce [
        ""
        "/run/wrappers/bin/oo7-daemon"
      ];
    };
}
