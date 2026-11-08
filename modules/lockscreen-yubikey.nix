# Unlock the Noctalia lock screen with a YubiKey touch, without a password or
# Enter. Fresh logins (greeter, console) stay password-only, which also
# unlocks Oo7. Noctalia is patched to run a helper while locked; the helper
# runs its own `noctalia-key` PAM stack holding only pam_u2f, with the same key
# file as sudo. Killing the helper cancels a pending touch.
{ inputs, ... }:
{
  flake.modules.nixos.lockscreen-yubikey =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      helper = pkgs.callPackage ../packages/noctalia-key-auth { };
    in
    lib.mkIf config.my.yubikey.enable {
      programs.noctalia.package =
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [ ../patches/noctalia-security-key-unlock.patch ];
          });

      systemd.user.services.noctalia.environment.NOCTALIA_SECURITY_KEY_HELPER = lib.getExe helper;

      security.pam.services.noctalia-key = {
        useDefaultRules = false;
        rules.auth.u2f = {
          order = 10000;
          control = "required";
          modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
          inherit (config.security.pam.u2f) settings;
        };
      };
    };
}
