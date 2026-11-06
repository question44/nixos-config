{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.my.user.name;
  mac = config.my.macApproval.enable;
  yubikey = config.my.yubikey.enable;
  # Bound the existing signature-only PAM service, without timing out the
  # caller's whole PAM stack (which would also prevent password fallback).
  macApprovalWithTimeout = pkgs.writeShellScript "mac-approval-with-timeout" ''
    test "$PAM_TYPE" = auth || exit 1
    test -n "$PAM_USER" || exit 1
    exec ${pkgs.coreutils}/bin/timeout --kill-after=2s 30s \
      ${pkgs.pamtester}/bin/pamtester mac-approval-check "$PAM_USER" authenticate </dev/null
  '';
  # WARNING: NixOS security.pam.services.*.rules is experimental and may
  # change incompatibly. Recheck generated PAM stacks on NixOS upgrades;
  # incompatible rules can lock users out or weaken authentication.
  boundedMacApproval = {
    modulePath = lib.mkForce "${pkgs.pam}/lib/security/pam_exec.so";
    settings = lib.mkForce { };
    args = lib.mkForce [
      "quiet"
      "seteuid"
      (toString macApprovalWithTimeout)
    ];
  };
in
{
  imports = [
    ./yubikey-touch-notify.nix
    ./approval-reason.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf mac {
      # Key material is provisioned locally, outside Git and the Nix store.
      # Never trust a key file writable by the account gaining privileges.
      security.pam.rssh = {
        enable = true;
        settings = {
          auth_key_file = "/etc/security/mac-approval/$user.keys";
          ssh_agent_addr = "/run/mac-approval/${user}/agent.sock";
        };
      };

      # Either forwarded Mac Touch ID approval or a local YubiKey touch is enough
      # for sudo. The sufficient PAM rules retain Unix password recovery.
      security.pam.services.sudo.rssh = true;
      security.pam.services.polkit-1.rssh = true;
      # Preserve the generated order and sufficient control. Timeout/failure
      # continues to U2F (sudo only), then the existing Unix password rule.
      security.pam.services.sudo.rules.auth.rssh = boundedMacApproval;
      security.pam.services.polkit-1.rules.auth.rssh = boundedMacApproval;

      # A diagnostic service verifies Mac approval without granting privileges
      # or allowing a password to hide an unavailable signing agent. Keep this
      # service unwrapped: the bounded helper invokes it, so wrapping it recurses.
      security.pam.services.mac-approval-check = {
        rssh = true;
        unixAuth = false;
      };

      # OpenSSH puts forwarded sockets here. Polkit's PAM helper hides /home;
      # expose only this socket directory while retaining its other protections.
      systemd.services."polkit-agent-helper@".serviceConfig = {
        ProtectHome = "tmpfs";
        BindReadOnlyPaths = [ "-/home/${user}/.ssh/agent" ];
      };
    })

    (lib.mkIf yubikey {
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
      # Key-touch login on the `login` stack, which greetd (substack), the
      # Noctalia lock screen and the console use. It runs after the password
      # check, so a typed password succeeds without waiting for a touch; an
      # empty or wrong password falls through to the touch. A touch login
      # leaves the Oo7 keyring locked (no password reaches pam_oo7).
      security.pam.services.login = {
        u2f = {
          enable = true;
          control = "sufficient";
        };
        rules.auth.u2f.order = config.security.pam.services.login.rules.auth.unix.order + 10;
      };
    })

    {
      # Single lists keep the original entry order across both features.
      systemd.tmpfiles.rules =
        lib.optional mac "d /etc/security/mac-approval 0755 root root -"
        ++ lib.optional yubikey "d /etc/security/yubico 0755 root root -"
        ++ lib.optionals mac [
          "d /run/mac-approval 0755 root root -"
          "d /run/mac-approval/${user} 0700 ${user} users -"
        ];

      environment.systemPackages = lib.optional mac pkgs.pamtester ++ lib.optional yubikey pkgs.pam_u2f;
    }
  ];
}
