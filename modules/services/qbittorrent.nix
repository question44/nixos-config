{ config, lib, ... }:
{
  config = lib.mkMerge [
    {
      my.services.qbittorrent = {
        port = 18081;
        localName = "torrent";
        publicName = "torrent";
        lanPort = 8082;
        # The Web UI checks Host/Origin/Referer against its public name.
        proxy.headers = [
          "Host torrent.${config.my.network.domain}"
          "Origin https://torrent.${config.my.network.domain}"
          "Referer https://torrent.${config.my.network.domain}/"
          "-Authorization"
        ];
        proxy.lanHeaders = [ ];
      };
    }
    (lib.mkIf config.my.services.qbittorrent.enable {
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "docker.io/linuxserver/qbittorrent:latest";
        ports = [ "127.0.0.1:18081:8080" ];
        volumes = [
          "/srv/qbittorrent/config:/config"
          "/srv/torrents:/downloads"
          "/srv/external/crucial:/downloads/crucial:rw"
          "/srv/external/seagate:/downloads/seagate:rw"
          "/srv/external/expansion:/downloads/expansion:rw"
          "/srv/external/bigdaddy:/downloads/bigdaddy:rw"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Warsaw";
          UMASK = "002";
          WEBUI_PORT = "8080";
          TORRENTING_PORT = "6881";
        };
      };
    })
  ];
}
