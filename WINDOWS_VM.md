# Windows 11 VM setup

## Current phase

Windows is installed. The Intel UHD 770 is assigned to the guest, with its
Windows driver and Direct3D 11 device creation verified. Linux uses the
NVIDIA RTX 4090. See SYSTEM_CHANGELOG.md for validation and recovery records.

Looking Glass is installed and streaming. It uses a matching Linux client and
Windows IDD, which supplies a virtual display and direct mouse/keyboard input.

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

The VM runs independently of a Linux desktop login; guest autostart is disabled.

Windows installation and VirtIO guest tools have subsequently been completed
by the user; the desktop and DHCP lease 192.168.122.2 were verified. Added a
persistent and live Unix virtio channel named org.qemu.guest_agent.0 to the
existing domain. The guest agent connected after detecting the new channel;
guest-ping succeeded without requiring a guest restart.
The Intel GPU was subsequently bound to vfio-pci and assigned through custom
OVMF firmware. Recovery copies from before assignment remain under
`/var/lib/windows-vm-recovery/pre-igd-20261018`.

## Looking Glass

Open **Windows (Looking Glass)** from the application launcher or
run `windows-looking-glass`. This starts the existing guest if necessary.
`Scroll Lock` toggles input capture; `Scroll Lock`+`F` toggles fullscreen;
`Scroll Lock`+`Q` closes the client without shutting down Windows.

Download the [matching Windows installer](https://looking-glass.io/artifact/B7-829-cdba29f2/idd).
Use `/S /ivshmem` for silent installation. Keep the IDD and Linux client at the same release.
Guest diagnostic logs are in `C:\ProgramData\Looking Glass (IDD)`.

The Windows `spice-agent` service is intentionally stopped with Manual startup:
its mouse handling prevented input through the original SPICE console. This
also disables SPICE clipboard sharing and automatic resize integration.
Looking Glass's IDD supplies input, display resizing, and clipboard integration
independently over LGMP.

The IDD normally makes its virtual display the only active Windows monitor.
If the SPICE console is blank, use Looking Glass. To restore another display,
disable **Make LG the only monitor** in the IDD helper preferences, then
enable the desired display in Windows settings. The QEMU guest-agent channel
is separate from SPICE and remains available for recovery.

Intel's direct shared-memory frame-copy path produced missing strips and
blocks while moving windows. The guest currently uses the IDD preference
**Force indirect copy** (`HKLM\SOFTWARE\LookingGlass\IDD`,
`ForceIndirectCopy=1`, `ForceFullDirectCopy=0`). The user verified a clean image
with this setting. Rendering remains accelerated on Intel; frame transport
uses an additional CPU copy. The original IDD settings are backed up at
`C:\ProgramData\LookingGlass-Setup\idd-before-artifact-fix.reg`.

Looking Glass USB Audio is connected through a dedicated SPICE USB channel.
The Windows audio device is healthy; physical speaker output was not tested.

The guest IDD default refresh is 164.900 Hz, matching the host monitor.
Its current dynamic mode was updated to that refresh too; changing
DefaultRefresh alone does not update an already stored ExtraMode when the
whole device is restarted. The previous settings are backed up at
`C:\ProgramData\LookingGlass-Setup\idd-before-high-refresh.reg`.
