{ config, lib, ... }:
{
  config = lib.mkMerge [
    {
      my.services.jellyfin = {
      port = 18096;
      localName = "jellyfin";
      publicName = "media";
      lanPort = 8096;
      };
    }
    (lib.mkIf config.my.services.jellyfin.enable {
      virtualisation.oci-containers.backend = "podman";
      virtualisation.oci-containers.containers.jellyfin = {
        image = "docker.io/jellyfin/jellyfin:10.11.11";
        ports = [ "127.0.0.1:18096:8096" ];
        volumes = [
          "/srv/jellyfin/config:/config"
          "/srv/jellyfin/cache:/cache"
          "/srv/torrents/complete:/media:ro"
          "/srv/external/crucial:/media-external/crucial:ro"
          "/srv/external/seagate:/media-external/seagate:ro"
          "/srv/external/expansion:/media-external/expansion:ro"
          "/srv/external/bigdaddy:/media-external/bigdaddy:ro"
        ];
        environment = {
          TZ = "Europe/Warsaw";
          JELLYFIN_PublishedServerUrl = "http://erebor:8096";
        };
        extraOptions = [ "--user=1000:1000" ];
      };
    })
  ];
}
