{ pkgs, ... }:

{
  imports = [ ./yubikey-touch-notify.nix ];

  # Key material is provisioned locally, outside Git and the Nix store.
  # Never trust a key file writable by the account gaining privileges.
  security.pam.rssh = {
    enable = true;
    settings = {
      auth_key_file = "/etc/security/mac-approval/$user.keys";
      ssh_agent_addr = "/run/mac-approval/janzon/agent.sock";
    };
  };

  # Either forwarded Mac Touch ID approval or a local YubiKey touch is enough
  # for sudo. The sufficient PAM rules retain Unix password recovery.
  security.pam.services.sudo.rssh = true;
  security.pam.services.polkit-1.rssh = true;

  # The credential mapping is provisioned locally after touching the key; it
  # is intentionally outside Git and the Nix store. A successful U2F
  # assertion authenticates sudo without a Unix password; Unix password
  # authentication remains the recovery path when the key is unavailable.
  security.pam.u2f = {
    control = "sufficient";
    settings = {
      authfile = "/etc/security/yubico/u2f_keys";
      cue = true;
    };
  };
  security.pam.services.sudo.u2f = {
    enable = true;
    control = "sufficient";
  };

  # A diagnostic service verifies Mac approval without granting privileges
  # or allowing a password to hide an unavailable signing agent.
  security.pam.services.mac-approval-check = {
    rssh = true;
    unixAuth = false;
  };

  systemd.tmpfiles.rules = [
    "d /etc/security/mac-approval 0755 root root -"
    "d /etc/security/yubico 0755 root root -"
    "d /run/mac-approval 0755 root root -"
    "d /run/mac-approval/janzon 0700 janzon users -"
  ];

  # OpenSSH puts forwarded sockets here. Polkit's PAM helper hides /home;
  # expose only this socket directory while retaining its other protections.
  systemd.services."polkit-agent-helper@".serviceConfig = {
    ProtectHome = "tmpfs";
    BindReadOnlyPaths = [ "-/home/janzon/.ssh/agent" ];
  };

  environment.systemPackages = [ pkgs.pamtester pkgs.pam_u2f ];
}
