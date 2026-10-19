# Windows 11 VM setup

## Current phase

Linux uses Intel UHD 770; Windows receives RTX 4090 and its HDMI audio
function. NVIDIA 610.88 is installed,
the GPU reports healthy, and explicit Direct3D 11 device creation on the
RTX 4090 succeeded. See SYSTEM_CHANGELOG.md for validation and recovery.

Looking Glass is installed, but its guest display device and QXL are currently
disabled. The SudoMaker virtual display is active. These guest display choices
were preserved during the GPU swap; Looking Glass streaming was not retested.

The intended guest has 8 virtual CPUs, 12 GiB RAM, a sparse 120 GiB qcow2
disk, Secure Boot, TPM 2.0, VirtIO storage/network, and a local SPICE display.
It uses a fresh virtual disk, never a physical Windows disk or partition.

## LAN access

The existing VM interface has been migrated live and persistently to the
configured LAN bridge, retaining MAC `52:54:00:d3:31:19`. Its router-issued
address was `192.168.1.120` on 2026-10-19. Verify the current address with
`virsh -c qemu:///system domifaddr windows11 --source agent`; reserve this
MAC in the router's DHCP configuration if a stable address is needed.
Moonlight clients on the LAN can add that address manually. Sunshine's
server-info endpoint and streaming TCP ports were reachable from the host.
Windows may block ping even while Sunshine is reachable.

The pre-migration persistent domain XML is saved at
`/home/janzon/.local/state/windows-vm/pre-lan-bridge-20261019/windows11.xml`.

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
`ip address show br0`. The LAN bridge must be active before starting the VM.
NetworkManager provides the bridge and wired port from the Nix configuration;
Windows obtains its LAN address from the router. The default NAT network can
remain available for other guests.
New group membership may require logging out and back in.

Run `windows-vm-create /absolute/path/to/windows11.iso /home/janzon/Downloads/windows-vm/virtio-win.iso`
and open Virtual Machine Manager, or `virt-viewer -c qemu:///system windows11`.
At disk selection, load the storage driver from the VirtIO CD's
`viostor/w11/amd64` directory. Install `virtio-win-guest-tools.exe` from that
CD inside Windows to provide network and other guest drivers.

## GPU assignment and recovery

Keep the Linux monitor on a motherboard video output. Verify Intel
`0000:00:02.0` uses i915 and both NVIDIA functions `0000:01:00.0` and
`0000:01:00.1` use vfio-pci before starting Windows.

The previous arrangement can be recovered with Windows shut off: restore
the domain using `virsh -c qemu:///system define
/var/lib/windows-vm-recovery/pre-gpu-swap-20261019/windows11.xml` with root
access and boot NixOS generation 171. This restores NVIDIA to Linux and
Intel to Windows. Offline disk/NVRAM/TPM and ESP backups are alongside the
XML; the read-only root snapshot is
`/btrfs-top/nixos-root-pre-gpu-swap-20261019`.

SPICE does not automatically capture the passed-through GPU's framebuffer.
Use the configured guest streaming software for the accelerated desktop.

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
