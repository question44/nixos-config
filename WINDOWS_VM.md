# Windows 11 VM setup

## Current phase

The virtualization module enables libvirt/KVM, virt-manager, TPM emulation,
and Intel IOMMU. The Intel GPU remains owned by Linux until its IOMMU group
and host usage have been checked after reboot. GPU passthrough is unfinished.

The intended guest has 8 virtual CPUs, 12 GiB RAM, a sparse 120 GiB qcow2
disk, Secure Boot, TPM 2.0, VirtIO storage/network, and a local SPICE display.
It uses a fresh virtual disk, never a physical Windows disk or partition.

## Installation media

Download the Windows 11 **x64 ISO** from
https://www.microsoft.com/en-us/software-download/windows11 and verify its
SHA-256 against Microsoft's table for the selected language/version.
Save it in `~/Downloads/windows-vm/`.

VirtIO drivers are downloaded separately from the stable ISO linked by
https://github.com/virtio-win/virtio-win-pkg-scripts to
`~/Downloads/windows-vm/virtio-win.iso`.

## After live activation

Verify `libvirtd.service`, `virsh -c qemu:///system list --all`, and
`virsh -c qemu:///system net-list --all`. The default NAT network must be
active; if inactive, start it with `virsh -c qemu:///system net-start default`
and enable it with `virsh -c qemu:///system net-autostart default`.
New group membership may require logging out and back in.

Run `windows-vm-create /absolute/path/to/windows11.iso /home/janzon/Downloads/windows-vm/virtio-win.iso`
and open Virtual Machine Manager, or `virt-viewer -c qemu:///system windows11`.
At disk selection, load the storage driver from the VirtIO CD's
`viostor/w11/amd64` directory. Install `virtio-win-guest-tools.exe` from that
CD inside Windows to provide network and other guest drivers.

## Before enabling GPU passthrough

1. Complete live validation, create and verify a recovery snapshot as required
   by AGENTS.md, and record the boot checkpoint before installing a boot entry.
2. Preserve firmware BootOrder/BootNext and Fedora/Windows EFI files. Record the
   new NixOS generation and retain generation 158 as the starting recovery entry.
3. Reboot when the user is ready. Check `/proc/cmdline` for `intel_iommu=on`
   and inspect `/sys/bus/pci/devices/0000:00:02.0/iommu_group/devices`.
   If groups remain absent, check firmware VT-d settings.
4. Check compositor and media-service use of the Intel render device before
   changing ownership. Bind only `8086:a780` to VFIO in a subsequent change.
5. Configure Intel IGD guest firmware/OpRegion requirements and test the Windows
   Intel driver, VM restart behavior, acceleration, and a suitable remote display.

SPICE provides the initial installation console; it does not automatically
capture the passed-through Intel GPU's framebuffer. RDP or another capture
method may be needed to use the accelerated Windows desktop in a Linux window.

## Created guest

`windows11` is created, with Windows Setup started from
`/home/janzon/Downloads/windows-vm/windws.is` (Polish x64 ISO, verified against
Microsoft's SHA-256 table). The fresh virtual disk is
`/var/lib/libvirt/images/windows11.qcow2`. Do not rerun windows-vm-create.

Local console: `virt-viewer --connect qemu:///system windows11`.
From another computer with Virt Viewer and SSH access to this host:
`virt-viewer --connect qemu+ssh://janzon@erebor/system windows11`
(replace erebor with a reachable host address if needed).
The SSH login gains current libvirtd group membership. The SPICE listener
stays on loopback; do not expose port 5900 to the network.

The VM runs independently of a Linux desktop login, but guest autostart is
currently disabled. Intel passthrough is unfinished.

Windows installation and VirtIO guest tools have subsequently been completed
by the user; the desktop and DHCP lease 192.168.122.2 were verified. Added a
persistent and live Unix virtio channel named org.qemu.guest_agent.0 to the
existing domain. The guest agent connected after detecting the new channel;
guest-ping succeeded without requiring a guest restart.
Host configuration is now persistent as generation 159. Reboot verification
passed: IOMMU enabled; Intel UHD 770 at 0000:00:02.0 is alone in group 0,
still using i915. The NVIDIA RTX 4090 remains on nvidia. Intel GPU binding,
guest firmware configuration and passthrough validation are still pending.
Recovery generation 158 and read-only snapshot
`/btrfs-top/nixos-root-pre-iommu-20261018` remain available.
