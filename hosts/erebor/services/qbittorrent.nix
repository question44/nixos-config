{ ... }:
{
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
}
