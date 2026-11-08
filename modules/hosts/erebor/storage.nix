# Data subvolume, external drives and the encrypted bigdaddy disk.
{
  flake.modules.nixos.erebor-storage =
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
      # ext4 so Samba can store the Mac's Time Machine metadata as xattrs.
      fileSystems."/srv/external/expansion" = {
        device = "/dev/disk/by-uuid/26efec95-f0a4-48ac-a696-5b71b21bdb48";
        fsType = "ext4";
        options = [
          "rw"
          "nofail"
          "x-systemd.automount"
          "x-systemd.device-timeout=30s"
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
      # Read 8 MiB ahead on spinning disks and the volumes on them, so seeding
      # from them needs fewer seeks. The SATA drives already report this size;
      # the USB Expansion drive and bigdaddy on it default to 1 MiB.
      # Cap dirty page cache for the Crucial MX500 (/srv/external/crucial) at
      # 1 GiB. strict_limit enforces it even while global dirty data is below
      # the free-run threshold, where max_bytes alone would not apply.
      services.udev.extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd[a-z]*|dm-[0-9]*", ATTR{queue/rotational}=="1", ATTR{bdi/read_ahead_kb}="8192"
        ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL}=="CT500MX500SSD1_1824E143D803", ATTR{bdi/max_bytes}="1073741824", ATTR{bdi/strict_limit}="1"
      '';
    };
}
