# The desktop in a VMware Fusion VM on the Mac

`nixosConfigurations.mac-vm` (`modules/hosts/mac-vm/`) is the shared
workstation (Umbriel, Noctalia, Vicinae, the apps) as an `aarch64-linux`
guest for VMware Fusion on the Apple Silicon MacBook. It is erebor without
its hardware and services: no NVIDIA, xremap, Windows VM or Looking Glass,
and every optional `my.*` feature off (ambilight, NanoKVM, Sunshine/Moonshine,
YubiKey, Mac and phone approval, the dashboard task board, the web services).
There is no `secrets/mac-vm.yaml`, so it declares no secrets.

The shared aspects drop what has no aarch64 build: Steam (with 32-bit
graphics), Discord, Claude Desktop, and the Intel media driver.
`ai-usagebar` and `trzsz` use their aarch64 release binaries. On erebor,
`nix flake check` evaluates the VM (`eval-mac-vm-aarch64`): it must
instantiate and contain no `x86_64-linux` package.

## What will not work in the VM

- Touchpad gestures, the Mac-like acceleration curve and the edge swipes:
  Fusion gives the guest a mouse with scrolling, not a multitouch touchpad,
  and macOS keeps three- and four-finger swipes.
- Clipboard and drag-and-drop with macOS can be unreliable under Wayland.
- Liquid glass runs on Fusion's OpenGL 4.3 (Metal underneath): expect it to
  be slower than on erebor. If Umbriel falls back to software rendering
  (`llvmpipe` in `glxinfo -B` / Umbriel's log), check that 3D acceleration is
  on in the VM settings.

## Create the VM

1. Download the NixOS **aarch64** minimal ISO (unstable, to match the
   flake's nixpkgs) from nixos.org.
2. In Fusion: New → install from the ISO; OS "Other Linux 6.x kernel 64-bit
   Arm". Before the first boot, in Settings:
   - Processors & Memory: 6+ cores, 12–16 GB (the first install compiles
     Umbriel, Noctalia, Vicinae, Strata and more).
   - Display: **Accelerate 3D Graphics** on, the most shared graphics
     memory; Retina full resolution if wanted.
   - Hard disk: 100 GB (the closure alone is about 16 GB).

## Install

In the installer (as root: `sudo -i`):

```bash
# GPT: 1 GiB ESP labelled BOOT, the rest ext4 labelled nixos,
# as _hardware-configuration.nix expects.
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 1GiB 100%
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2
mount /dev/disk/by-label/nixos /mnt
mount --mkdir -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
```

Get the configuration into `/mnt/etc/nixos`. The submodules are private
GitHub repositories, so either add an SSH key the GitHub account accepts and
clone, or copy a checkout over from erebor or the Mac:

```bash
nix-shell -p git --run 'git clone --recurse-submodules git@github.com:question44/nixos-config.git /mnt/etc/nixos'
# or, from erebor: rsync -a /etc/nixos/ root@<vm-ip>:/mnt/etc/nixos/
```

Check that the guessed hardware matches: `nixos-generate-config --show-hardware-config`
should list the same initrd modules as `modules/hosts/mac-vm/_hardware-configuration.nix`,
and `ip link` should show `ens160` (`my.network.lanInterface` in
`modules/hosts/mac-vm/default.nix`); adjust them if not.

Install. Builds go to the target disk, since the installer's `/tmp` is RAM:

```bash
mkdir -p /mnt/tmp
TMPDIR=/mnt/tmp nixos-install --flake '/mnt/etc/nixos?submodules=1#mac-vm'
nixos-enter --root /mnt -c 'passwd janzon'
reboot
```

After the reboot the Noctalia greeter starts Umbriel. Update later from
inside the VM with
`sudo nixos-rebuild switch --flake '/etc/nixos?submodules=1#mac-vm'`.
