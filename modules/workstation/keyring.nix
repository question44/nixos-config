# Oo7 Secret Service: daemon, portal and greetd PAM unlock.
{ config, lib, pkgs, ... }:
let
  oo7Pam = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "oo7-pam";
    inherit (pkgs.oo7) version src cargoDeps;
    sourceRoot = "${finalAttrs.src.name}/pam";
    cargoRoot = "../";

    nativeBuildInputs = with pkgs; [
      pkg-config
      meson
      ninja
      rustPlatform.cargoSetupHook
      rustc
      cargo
    ];
    buildInputs = [ pkgs.systemdLibs ];
  });
in
{
  security.pam.services.greetd.rules.auth.unix_early = {
    order = config.security.pam.services.greetd.rules.auth.unix.order - 20;
    control = "optional";
    modulePath = "${pkgs.linux-pam}/lib/security/pam_unix.so";
    settings = {
      likeauth = true;
      nullok = true;
    };
  };
  security.pam.services.greetd.rules.auth.oo7 = {
    order = config.security.pam.services.greetd.rules.auth.unix_early.order + 10;
    control = "optional";
    modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
  };
  security.pam.services.greetd.rules.session.oo7 = {
    order = config.security.pam.services.greetd.rules.session.systemd.order + 10;
    control = "optional";
    modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
    settings.auto_start = true;
  };

  services.dbus.packages = [ pkgs.oo7-server ];
  services.gnome.gnome-keyring.enable = false;

  systemd.packages = [ pkgs.oo7-server pkgs.oo7-portal ];
  systemd.user.services.oo7-daemon = {
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = lib.mkForce [ "" "/run/wrappers/bin/oo7-daemon" ];
  };

  security.wrappers.oo7-daemon = {
    owner = "root";
    group = "root";
    capabilities = "cap_ipc_lock=ep";
    source = "${pkgs.oo7-server}/libexec/oo7-daemon";
  };
}
