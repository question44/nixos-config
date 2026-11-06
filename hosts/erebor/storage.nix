# Data subvolume, external drives and the encrypted bigdaddy disk.
{ ... }:
{
  fileSystems."/srv" = {
    device = "/dev/disk/by-uuid/5be9be17-20c9-4a47-ba2d-6adf1ceb4c55";
    fsType = "btrfs";
    options = [
      "subvol=srv"
      "compress=zstd:1"
    ];
  };
  fileSystems."/srv/external/crucial" = {
    device = "/dev/disk/by-uuid/604F-A363";
    fsType = "exfat";
    options = [
      "rw"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "uid=1000"
      "gid=1000"
      "fmask=0002"
      "dmask=0002"
    ];
  };
  fileSystems."/srv/external/seagate" = {
    device = "/dev/disk/by-uuid/7ACF-F05A";
    fsType = "exfat";
    options = [
      "rw"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "uid=1000"
      "gid=1000"
      "fmask=0002"
      "dmask=0002"
    ];
  };
  fileSystems."/srv/external/expansion" = {
    device = "/dev/disk/by-uuid/7FF9-F492";
    fsType = "exfat";
    options = [
      "rw"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=30s"
      "uid=1000"
      "gid=1000"
      "fmask=0002"
      "dmask=0002"
    ];
  };
  fileSystems."/srv/external/bigdaddy" = {
    device = "/dev/mapper/bigdaddy";
    fsType = "ext4";
    options = [
      "rw"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=30s"
    ];
  };
  environment.etc."crypttab".text = ''
    bigdaddy UUID=35aa0d36-fe4f-45ce-8843-2c0387d1475a /etc/cryptsetup-keys.d/bigdaddy.key luks,noauto,nofail,x-systemd.device-timeout=30s
  '';
}
