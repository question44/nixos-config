# Placeholder so the template evaluates. Replace with the output of
# nixos-generate-config on the real machine.
{
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/BOOT"; fsType = "vfat"; };
}
