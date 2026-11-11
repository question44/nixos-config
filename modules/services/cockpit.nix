# Cockpit system console (served at sys.<domain>).
{
  flake.modules.nixos.cockpit =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domain = config.my.network.domain;
    in
    {
      config = lib.mkMerge [
        {
          my.services.cockpit = {
            port = 9090;
            publicName = "sys";
          };
        }
        (lib.mkIf config.my.services.cockpit.enable {
          services.cockpit = {
            enable = true;
            plugins = [ pkgs.cockpit-files ];
            openFirewall = false;
            allowed-origins = [
              "https://sys.${domain}"
              "wss://sys.${domain}"
            ];
            settings.WebService = {
              AllowUnencrypted = true;
              LoginTo = false;
              ProtocolHeader = "X-Forwarded-Proto";
            };
          };
        })
      ];
    };
}
