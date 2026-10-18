{ pkgs, ... }:

{
  # Key material is provisioned locally, outside Git and the Nix store.
  # Never trust a key file writable by the account gaining privileges.
  security.pam.rssh = {
    enable = true;
    settings = {
      auth_key_file = "/etc/security/mac-approval/$user.keys";
      ssh_agent_addr = "/run/mac-approval/janzon/agent.sock";
    };
  };

  # rssh is sufficient: rejection or a disconnected Mac falls back to Unix
  # password authentication. Login and screen-lock authentication stay as-is.
  security.pam.services.sudo.rssh = true;
  security.pam.services.polkit-1.rssh = true;

  # A diagnostic service verifies Mac approval without granting privileges
  # or allowing a password to hide an unavailable signing agent.
  security.pam.services.mac-approval-check = {
    rssh = true;
    unixAuth = false;
  };

  systemd.tmpfiles.rules = [
    "d /etc/security/mac-approval 0755 root root -"
    "d /run/mac-approval 0755 root root -"
    "d /run/mac-approval/janzon 0700 janzon users -"
  ];

  # OpenSSH puts forwarded sockets here. Polkit's PAM helper hides /home;
  # expose only this socket directory while retaining its other protections.
  systemd.services."polkit-agent-helper@".serviceConfig = {
    ProtectHome = "tmpfs";
    BindReadOnlyPaths = [ "-/home/janzon/.ssh/agent" ];
  };

  environment.systemPackages = [ pkgs.pamtester ];
}
