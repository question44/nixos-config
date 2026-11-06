# OpenSSH with public key, or TOTP plus password.
{ lib, ... }:
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
  };
  # Each user provisions ~/.google_authenticator by running google-authenticator.
  security.pam.services.sshd = {
    googleAuthenticator.enable = true;
    # The openssh module ties unixAuth to PasswordAuthentication; without it
    # the stack is pam_deny alone and the TOTP rule is omitted.
    unixAuth = lib.mkForce true;
  };
}
