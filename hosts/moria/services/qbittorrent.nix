{ ... }:
{
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "docker.io/linuxserver/qbittorrent:latest";
    ports = [ "127.0.0.1:18081:8080" ];
    volumes = [
      "/var/lib/moria/qbittorrent/config:/config"
      "/srv/torrents:/downloads:ro"
      "/srv/external/crucial:/downloads/crucial:ro"
      "/srv/external/seagate:/downloads/seagate:ro"
      "/srv/external/expansion:/downloads/expansion:ro"
      "/srv/external/bigdaddy:/downloads/bigdaddy:ro"
      "/var/lib/moria/torrents:/nixos-downloads"
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
