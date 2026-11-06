{ config, lib, ... }:
{
  config = lib.mkMerge [
    {
      my.services.syncthing = {
        port = 18384;
        localName = "syncthing";
        publicName = "sync";
        lanPort = 8384;
        # The GUI rejects requests whose Host/Origin is not its own address.
        proxy.headers = [
          "Host localhost:18384"
          "Origin http://localhost:18384"
        ];
      };
    }
    (lib.mkIf config.my.services.syncthing.enable {
      virtualisation.oci-containers.containers.syncthing = {
        image = "docker.io/syncthing/syncthing:2.1.6";
        volumes = [ "/srv/syncthing:/var/syncthing" ];
        environment = {
          STGUIADDRESS = "127.0.0.1:18384";
          TZ = "Europe/Warsaw";
        };
        extraOptions = [ "--network=host" ];
      };
    })
  ];
}
