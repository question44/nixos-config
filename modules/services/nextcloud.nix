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
      my.services.nextcloud = {
        port = 18089;
        localName = "nextcloud";
        publicName = "cloud";
        lanPort = 8095;
        extraConfig = ''
          @carddav path /.well-known/carddav
          redir @carddav /remote.php/dav 301
          @caldav path /.well-known/caldav
          redir @caldav /remote.php/dav 301
        '';
      };
    }
    (lib.mkIf config.my.services.nextcloud.enable {
      virtualisation.oci-containers.containers = {
        nextcloud-db = {
          image = "docker.io/library/postgres:17-alpine";
          volumes = [ "/srv/nextcloud/db:/var/lib/postgresql/data" ];
          environmentFiles = [ "/etc/nextcloud/db.env" ];
          extraOptions = [ "--ip=10.88.0.20" ];
        };
        nextcloud-redis = {
          image = "docker.io/library/redis:alpine";
          extraOptions = [ "--ip=10.88.0.21" ];
        };
        nextcloud = {
          image = "docker.io/library/nextcloud:34.0.2-apache";
          dependsOn = [
            "nextcloud-db"
            "nextcloud-redis"
          ];
          ports = [ "127.0.0.1:18089:80" ];
          volumes = [
            "/srv/nextcloud/html:/var/www/html"
            "/srv/nextcloud/data:/var/www/data"
            "/srv/torrents/complete:/var/www/downloads:ro"
            "/srv/external/crucial:/var/www/external/crucial:ro"
            "/srv/external/seagate:/var/www/external/seagate:ro"
            "/srv/external/expansion:/var/www/external/expansion:ro"
            "/srv/external/bigdaddy:/var/www/external/bigdaddy:ro"
          ];
          environmentFiles = [ "/etc/nextcloud/db.env" ];
          environment = {
            POSTGRES_HOST = "nextcloud-db";
            REDIS_HOST = "nextcloud-redis";
            NEXTCLOUD_DATA_DIR = "/var/www/data";
            NEXTCLOUD_TRUSTED_DOMAINS = "erebor cloud.${domain} localhost 127.0.0.1";
            PHP_UPLOAD_LIMIT = "10G";
            PHP_MEMORY_LIMIT = "1G";
          };
          extraOptions = [
            "--group-add=1000"
            "--add-host=nextcloud-db:10.88.0.20"
            "--add-host=nextcloud-redis:10.88.0.21"
          ];
        };
      };

      systemd.services.nextcloud-cron = {
        description = "Run Nextcloud background jobs";
        after = [ "podman-nextcloud.service" ];
        requires = [ "podman-nextcloud.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.podman}/bin/podman exec --user 33 nextcloud php -f /var/www/html/cron.php";
        };
      };
      systemd.timers.nextcloud-cron = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/5";
          Persistent = true;
        };
      };
    })
  ];
}
