{ ... }:
{
  virtualisation.oci-containers.containers.syncthing = {
    image = "docker.io/syncthing/syncthing:2.1.6";
    volumes = [ "/srv/syncthing:/var/syncthing" ];
    environment = {
      STGUIADDRESS = "127.0.0.1:18384";
      TZ = "Europe/Warsaw";
    };
    extraOptions = [ "--network=host" ];
  };
}
