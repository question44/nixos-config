# T3 Code web server (served at code.erebor.jzon.pl).
{ config, lib, pkgs, ... }:
let
  user = config.my.user.name;
  t3codeStart = pkgs.writeShellScript "t3code-start" ''
    export PATH="/home/${user}/.local/bin:$PATH"
    exec /home/${user}/.local/bin/t3 serve --mode web --host 127.0.0.1 --port 3773 --base-dir /home/${user}/.t3/server
  '';
in
{
  systemd.user.services.t3code = {
    description = "T3 Code web server";
    # Global user unit: only janzon's lingering manager may run it; other
    # managers (e.g. greeter) cannot enter /home/janzon and would crash-loop.
    unitConfig.ConditionUser = "${user}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];
    environment = {
      HOME = "/home/${user}";
      # T3 downloads an upstream Chromium binary. Its loader and dependency
      # check need these libraries in the server's environment on NixOS.
      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
        glib nspr nss at-spi2-core dbus
        libx11 libxcomposite libxdamage libxext libxfixes libxrandr
        libgbm expat libxcb libxkbcommon systemdLibs alsa-lib
        fontconfig freetype
      ]);
    };
    serviceConfig = {
      WorkingDirectory = "/home/${user}/Projects";
      ExecStart = t3codeStart;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
