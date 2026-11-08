# OpenSSH with public key, or TOTP plus password.
{
  flake.modules.nixos.ssh =
    { config, lib, ... }:
    let
      mac = config.my.macApproval;
    in
    {
      services.openssh = {
        enable = true;
        # Ports are opened per interface in default.nix, not globally.
        openFirewall = false;
        # Keys alone, or a TOTP code plus the Unix password through PAM.
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = true;
          AuthenticationMethods = "publickey keyboard-interactive";
        };
        # A sleeping MacBook keeps its session half-open (macOS answers TCP
        # keepalives while asleep), which stalls sudo's Mac approval step. sshd
        # cannot match on keys, so match the MacBook's Tailscale and LAN addresses.
        extraConfig = lib.mkIf (mac.enable && mac.addresses != [ ]) ''
          Match Address ${lib.concatStringsSep "," mac.addresses}
            ClientAliveInterval 60
            ClientAliveCountMax 3
        '';
      };
      # Each user provisions ~/.google_authenticator by running google-authenticator.
      security.pam.services.sshd = {
        googleAuthenticator.enable = true;
        # The openssh module ties unixAuth to PasswordAuthentication; without it
        # the stack is pam_deny alone and the TOTP rule is omitted.
        unixAuth = lib.mkForce true;
      };
    };
}
