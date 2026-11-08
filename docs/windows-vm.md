# Windows 11 VM setup

## Current phase

GPU ownership is chosen in the GRUB menu ([SYS-073](../SYSTEM_TODO.md#sys-073)).
The default entry keeps the RTX 4090 on Linux
(`virtualisation.windowsGpuPassthrough.enable = false` in
`modules/hosts/erebor/default.nix`). Each generation also has a
**gpu-passthrough** entry (`specialisation.gpu-passthrough`) that reserves both
NVIDIA functions for Windows, disables the host NVIDIA driver and runs Linux on
Intel UHD 770; Ollama and Moonshine are off there, and Sunshine, if
re-enabled, would encode with VA-API.

To switch: shut down `windows11`, reboot, pick the entry, and move the monitor
cable (motherboard output for gpu-passthrough, RTX 4090 for the default).
Switching a running system to the other specialisation is unsupported: the
GPU binds early in boot. The gpu-passthrough entry needs the Intel iGPU
enabled in firmware; without it Linux has no display, and the default entry is
the way back. The `windows-vm-gpu` service synchronizes the existing domain's PCI assignments
and backs up every changed XML under `/var/lib/windows-vm-recovery/gpu-toggle/`.
It refuses to change the assignments while Windows is running. Disk, NVRAM,
TPM, CPU, memory and networking settings are preserved.

Prior to disabling passthrough, NVIDIA 610.88 and Direct3D 11 acceleration
were verified in Windows. GPU-dependent guest streaming is unavailable while
the RTX 4090 belongs to Linux. No guest display settings are changed by this toggle.

Looking Glass is installed, but its guest display device and QXL are currently
disabled. The SudoMaker virtual display is active. These guest display choices
were preserved during the GPU swap; Looking Glass streaming was not retested.

The guest has 20 virtual CPUs, 20 GiB RAM, a sparse 120 GiB qcow2
disk, Secure Boot, TPM 2.0, VirtIO storage/network, and a local SPICE display.
It uses a fresh virtual disk, never a physical Windows disk or partition.

## Disk location and recovery

The existing VM uses `/srv/external/crucial/windows11.qcow2` on Crucial
filesystem UUID `604F-A363`. Keep Crucial connected and mounted read-write
before starting Windows. Offline content comparison, qcow2 checks and a
Windows desktop boot passed on 2026-10-23; the live original under
`/var/lib/libvirt/images/` was removed after a clean guest shutdown.

Original domain XML, NVRAM and TPM state are saved under root-only
`/var/lib/windows-vm-recovery/crucial-relocation-20261023`. The original disk
still exists inside read-only NixOS recovery snapshots, including
`/btrfs-top/nixos-root-pre-vm-crucial-20261023/var/lib/libvirt/images/windows11.qcow2`.
These snapshots retain its disk space despite deletion of the live original.

Older saved domain XML references the removed local path. With Windows off,
update its disk source to the current Crucial image before using such XML,
or restore the matching original disk and firmware/TPM state together.
Do not start an older disk against newer state without reviewing that rollback.

## CPU and memory

The persistent libvirt domain assigns each vCPU 0-19 to the corresponding
host logical CPU 0-19, covering all six SMT performance cores and eight
single-thread efficiency cores. Emulator threads may run on CPUs 0-19.
The host scheduler shares these CPUs; no cores are reserved exclusively
for the guest. Guest topology uses one socket and 20 single-thread virtual
cores to accommodate the mixed host core types. RAM remains 20 GiB.
The pre-change domain XML is saved at
`/home/janzon/.local/state/windows-vm/pre-all-cpus-20261019/windows11.xml`.
Creation defaults in Nix use 20 GiB and 20 vCPUs restricted to CPUs 0-19;
the existing domain's exact per-thread pins are stored persistently in libvirt.

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

With passthrough disabled, connect the monitor to the NVIDIA card to use its
physical outputs. The motherboard output can continue to use Intel graphics.
With passthrough enabled, keep the Linux monitor on the motherboard output;
verify Intel `0000:00:02.0` uses i915 and both NVIDIA functions
`0000:01:00.0` and `0000:01:00.1` use vfio-pci before starting Windows.

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
Microsoft's SHA-256 table). The virtual disk now lives at
`/srv/external/crucial/windows11.qcow2`; see disk recovery above. Do not rerun
windows-vm-create.

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

Download the [matching Windows installer](https://looking-glass.io/artifact/B7-895-432f4a0c/idd).
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
