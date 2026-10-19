# NixOS system change log for `erebor` (flake target `moria`)

## [COMPLETED] Swap host and Windows GPUs — 2026-10-19

Intel UHD 770 now drives Linux and RTX 4090 is assigned to the Windows VM.
Generation 172 is booted, active and persistent:
/nix/store/207r6picj0fa2q7bhv0wb44pjl6y9yc7-nixos-system-erebor-26.05.20261013.a033e66.
Generation 171 is retained as the recovery boot entry:
/nix/store/dw9l4lk86ccckmhi7kvxwyf2baczg5v3-nixos-system-erebor-26.05.20261013.a033e66.
The user rebooted after staging and confirms the Linux monitor is connected
to a motherboard video output.

Flake checks, dry builds and full builds passed. Preserved the sudo/YubiKey
configuration already active in generation 171; its unrelated source edits
remain uncommitted. The installed target reserves 10de:2684 and 10de:22ba
for VFIO, blacklists NVIDIA host drivers and loads i915 for Linux. Both
NVIDIA PCI functions share an otherwise isolated IOMMU group. The persistent
windows11 domain assigns 0000:01:00.0 and 0000:01:00.1 with managed=no;
Intel assignment was removed. XML validates and its non-hostdev contents
were verified unchanged before libvirt assigned the new guest PCI addresses.
Existing firmware, NVRAM, TPM, disk and Looking Glass configuration are kept.
Windows was cleanly stopped for staging and is now running successfully.

The user ran the reviewed staging script with local sudo authentication.
It checks the offline qcow2, saves disk/XML/NVRAM/TPM and ESP recovery copies,
checks foreign EFI hashes and firmware entries, and retains generation 171.
Recovery directory: /var/lib/windows-vm-recovery/pre-gpu-swap-20261019
(root-only; audit contents were not independently readable by this agent).
Read-only root snapshot: /btrfs-top/nixos-root-pre-gpu-swap-20261019,
independently verified ro=true. Snapper is not configured. The correct root
and ESP UUIDs were rechecked. Boot entry 172 references the built target and
its installed initrd; entry 171 and its older initrd remain available.

Post-reboot verification: Intel 0000:00:02.0 uses i915; both NVIDIA functions
use vfio-pci. Umbriel's live log reports the Intel Mesa iris renderer, with
DP-1 at 3440x1440@99.982 Hz. Libvirtd and the guest agent work, the correct
root/ESP UUIDs remain mounted, and no system or user units have failed.
Windows initially used Microsoft Basic Display Adapter. Windows Update
automatically installed NVIDIA 32.0.16.1088 (610.88), reporting success; the
agent's narrowly targeted install attempt found it already installed and
made no additional driver changes. RTX 4090 reports device status 0.
An explicit DXGI enumeration targeting vendor 10de/device 2684 followed by
D3D11CreateDevice succeeded (HRESULT 0, feature level 0xB000). nvidia-smi
reports RTX 4090, driver 610.88 and 24564 MiB of memory.
Looking Glass and QXL are currently disabled in the guest (device code 22),
while the SudoMaker virtual display is healthy; preserved this existing
guest display setup. Looking Glass streaming was therefore not retested.
No further host reboot or Windows restart was required for acceleration.
Recovery: with Windows off, restore windows11.xml from the recovery directory
using virsh define and boot generation 171 to restore the former GPU split.

## [COMPLETED] Release Noctalia bar reservation during auto-hide — 2026-10-19

Update the declarative `noctalia-bar-autohide` utility so enabling smart or
regular auto-hide also releases the default bar's compositor reservation, and
switching back off restores it. `nix flake check` and a dry build passed.
Activated using Polkit; generation 170 is active. The live smart-to-off test
returned success from both reservation and auto-hide IPC calls, ending with
the bar visible and reservation restored.

## [COMPLETED] Add a declarative Noctalia smart-auto-hide control — 2026-10-19

Added `~/.local/bin/noctalia-bar-autohide`, a session-scoped toggle between
disabled and smart auto-hide for Noctalia's default bar, with a custom button
at the far left of that bar. `nix flake check`, Noctalia config validation,
and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated with
`pkexec`; generation 168 is active. Noctalia reloaded successfully, the
deployed utility resolved from the new Home Manager generation, and its
smart-to-off runtime transition was verified via Noctalia IPC.

## [PENDING] Route HyperHDR through Umbriel's wallpaper-only virtual output — 2026-10-19

Activated a declarative Umbriel `ambilight` virtual output at 3440x1440@30,
placed beside DP-1 without moving the physical monitor, and configured
Noctalia to render the same wallpaper there. Live verification confirms the
output is enabled and has only `noctalia-wallpaper` and `dropwall` background
layers. Added `blur_popups = true` to Umbriel's global window blur rule so
Qt descendant XDG popups (including Dolphin menus) receive live-content blur;
validated and reloaded it in the live Umbriel session. `nix flake check`,
Umbriel configuration validation, and activated NixOS builds passed; the active system is
`/nix/store/lgvpgqlisca4qd9c85svp3an8gr289wq-nixos-system-erebor-26.05.20261013.a033e66`.

Mandatory next action: approve Umbriel's screencast target change to
`ambilight`, if its confirmation is visible, or reselect `ambilight` in
HyperHDR's PipeWire capture picker. Verify that opening or moving a window
does not change the LEDs, then replace this entry with `[COMPLETED]`.

## [COMPLETED] Match Looking Glass to the host's high refresh rate — 2026-10-18

Niri reports the Dell AW3423DWF on DP-1 already running at 3440x1440,
164.900 Hz. The Windows IDD had no explicit DefaultRefresh (60 Hz default).
Exported its settings to
C:\ProgramData\LookingGlass-Setup\idd-before-high-refresh.reg, set
HKLM\SOFTWARE\LookingGlass\IDD\DefaultRefresh to REG_SZ "164.900", and
restarted only ROOT\DISPLAY\0001. Retain ForceIndirectCopy=1, the verified
artifact workaround. No host configuration, generation, or boot change.
The retained ExtraMode still explicitly selected 1696x1368@60, so changed
only that mode's refresh to 164.900 as well and reloaded the display device.
Verified the IDD log reports ExtraMode 1696x1368@164.9000*, Windows reports
CurrentRefreshRate=164 (integer API value). Future dynamic resolutions use
the new default refresh.
This verifies display timing, not sustained application/game frame rates.

## [COMPLETED] Set up Looking Glass for the Windows VM — 2026-10-18

Use matching pinned B7-829-cdba29f2 Linux client and Windows IDD. The IDD
creates a virtual monitor and supplies direct input, avoiding dependence on
an Intel physical output and the guest's broken SPICE-agent mouse path.
Add a declarative KVMFR module (128 MiB), device permissions, libvirt access,
client configuration, and Windows launcher. Keep existing guest GPU assignment
and console configuration. Build from isolated HEAD plus the existing VFIO
module/firmware changes and this task, excluding unrelated flake edits.
Starting persistent/live host generation: 161. Root and ESP UUIDs match the
system instructions; no failed system units. Before guest changes, cleanly
stop Windows and preserve offline disk, NVRAM, TPM, and XML recovery copies.
Create a verified root snapshot and EFI backup before persistent activation.
Test-activate the built host, assign IVSHMEM at free guest PCI slot 00:05.0,
install the matching signed Windows drivers, and verify Intel rendering,
Looking Glass video and direct input before recording completion.

Validation checkpoint: flake check, dry-build and full build passed. Tested
host is /nix/store/x3zi5f12kyzcprmlxvnlzar0hq71vcnd-nixos-system-erebor-26.05.20261013.a033e66;
persistent generation remains 161 before activation. Recovery directory
/var/lib/windows-vm-recovery/pre-looking-glass-20261018 contains the clean
qcow2 reflink (qemu-img check passed), NVRAM, TPM, exact XML, EFI archive and
foreign-OS EFI hashes. Read-only root snapshot
/btrfs-top/nixos-root-pre-looking-glass-20261018 is verified ro=true.
KVMFR is loaded from the tested generation's module directory; default
modprobe searches the booted generation instead. Its ioctl reports exactly
134217728 bytes, accessible as janzon:kvm with mode 0660. Restarted libvirtd
to copy/load the new qemu.conf ACL. Existing domain changes made concurrently
were recovered from the offline XML; preserved its Intel ROM setting and
added IVSHMEM, disabled ballooning, and added loopback SPICE for audio/fallback.
Windows installer archive SHA256
bf91dbe3b69d369f8180247881739144308c2c0f6c85785ab8220d8a8e4b2665;
installer and driver catalogs have valid HostFission/Sectigo signatures.
Silent driver installation required adding the verified leaf certificate
57476AACDE410C05A63E9FEC8B97938605B9D8F5 to LocalMachine TrustedPublisher;
no root certificate or Secure Boot policy was changed. Installer exit 0;
LGIddHelper is running with Automatic startup; display/input/IVSHMEM devices
report OK. Secure Boot is still enabled. Guest IDD log selects Intel UHD 770
(8086:a780), hardware D3D12 transport, 128 MiB IVSHMEM. Linux client uses
EGL on RTX 4090, DMA buffers, LGMP video/input/clipboard; desktop screenshot
and live mouse events verified. Guest resolution follows the Niri window.
Persisted this exact target as generation 162. Generation 161 is retained;
all Microsoft/Fedora/moria EFI hashes pass and the firmware before/after
files are byte-identical. No system/user units failed; NVIDIA remains the
Linux GPU and Intel remains bound to vfio-pci. No host reboot performed.
User confirmed Looking Glass display, mouse and keyboard work. The normal
launcher was reopened without debug input tracing and reconnects successfully.
Added one persistent/live SPICE USB-redirection device for Looking Glass USB
audio: client reports USB Audio active and Windows reports its audio device
and endpoint healthy. Actual speaker output was not checked.
User then reported visible render artifacts; screenshot showed corrupted
strips in a notification. Backed up guest IDD settings to
C:\ProgramData\LookingGlass-Setup\idd-before-artifact-fix.reg and enabled
HKLM\SOFTWARE\LookingGlass\IDD\ForceFullDirectCopy=1. Restarted only the
virtual display device; driver log confirms full direct transport copies and
continued Intel rendering. Full-frame direct copies did not resolve the
corruption. Set ForceFullDirectCopy=0 and ForceIndirectCopy=1 and restarted
only the virtual display device again. The user confirmed the artifacts are
gone. Intel still renders through D3D12; the transport now uses a CPU copy
through readback memory, trading some bandwidth for correct frames. This
setting persists in the guest registry. Client video/input/clipboard remain
on LGMP; SPICE guest-agent service remains stopped. User-confirmed display,
mouse and keyboard work. No additional host rebuild or reboot was required
for the guest compatibility setting. Guest/host cold reboot with the final
IDD configuration has not been tested; current live operation is verified.
Existing CPU topology was retained; the client reports two guest logical
processors despite the domain's eight-vCPU allocation. That is a separate
performance follow-up.

## [COMPLETED] Restore Windows VM mouse input — 2026-10-18

The windows11 guest showed no pointer and ignored viewer mouse input while
its Windows spice-agent service was running. Restarting that service did not
resolve it. Direct QEMU USB-tablet movement reached Windows and changed its
cursor state from suppressed to showing. Stopping spice-agent restored mouse
input in the existing SPICE viewer; the user confirmed it works.
Set only that guest service to Manual startup and verified State=Stopped,
StartMode=Manual, preserving the working tablet input path after guest boot.
Clipboard integration and automatic display resizing are unavailable while
this service is stopped. To revert inside Windows, set spice-agent startup
to Automatic and start it. No host generation, GPU assignment, domain XML,
or Windows pointer preference changed. Guest restart persistence is configured
but has not yet been tested with another restart.

## [COMPLETED] Add Oo7 keyring password maintenance helper — 2026-10-18

Added `make keyring-change-password`, invoking `scripts/oo7-change-password.py`
as the desktop user. The helper reads hidden passwords, backs up encrypted
keyrings outside the daemon's collection directory with private permissions,
and sends Oo7 0.6's PAM password-change message over the user's socket. It
restarts the daemon only if the socket is missing and returns failure if no
persistent keyring update is detected. It does not change the account password.
Verified Makefile help and dry-run, Python syntax/help, and an isolated fake
socket exchange including message decoding, file-update detection, backup
contents/permissions, and mismatch rejection. No live password change was run.
No Nix configuration or running generation changed; no rebuild is required.

## [PENDING] Assign Intel UHD 770 to Windows — 2026-10-18

Post-IOMMU baseline: generation 159, Intel 8086:a780 at 0000:00:02.0 alone in
IOMMU group 0, no host processes hold /dev/dri/card0 or renderD128. NVIDIA
RTX 4090 remains the host GPU. Guest agent and QXL display are healthy.
Prepare pinned VfioIgdPkg 067328df2554c865cc0078cb922357301c4c36c6's
IgdAssignmentDxe inside OVMFFull, as recommended by QEMU IGD documentation.
Keep existing Microsoft-keyed guest NVRAM and QXL/SPICE console. Build only
isolated HEAD plus this change, excluding unrelated flake edits. Before
changing the guest, check BitLocker, shut down cleanly, and preserve offline
disk/NVRAM/TPM/domain recovery copies. Move virtual root ports away from
guest 00:02.0, assign only the isolated Intel device, and limit guest physical
address width to the host IOMMU's verified 39 bits. Start and verify Windows,
QXL console, guest agent, Intel driver status and host GPU/services. Do not
claim passthrough complete until Intel acceleration works in Windows.

Built custom OVMF successfully; flake check, dry-build, full build, and test
activation passed. Intel host device detached to vfio-pci, assigned as guest
00:02.0; guest root ports previously occupying that slot moved to slot 04.
Guest firmware CODE is
/nix/store/lfpc063w74lbwqzb6jzisx9sf211h6wa-OVMF-vfio-igd-202602-fd/FV/OVMF_CODE.fd.
Windows booted, QXL/SPICE and guest agent work. Device initially had code 28
(driver missing); Windows Update installed Intel 32.0.101.6129, now reports
Intel UHD 770 healthy with code 0. Installing Intel's current 32.0.101.7092
from official downloadmirror URL after SHA-512 and Authenticode verification.
Offline guest recovery copies are in /var/lib/windows-vm-recovery/pre-igd-20261018:
reflink-cloned disk, original XML, NVRAM and TPM state. BitLocker reports
encrypted volume but ProtectionStatus=Off; no recovery secrets were read.
Added early vfio-pci binding for only 8086:a780 to the module; validated and
test-activated system /nix/store/ly2hfh2bmp7hfgs53464rcvad9njna7b-nixos-system-erebor-26.05.20261013.a033e66.
Persistent boot profile remains generation 159 until further verification.

Intel 32.0.101.7092 is installed and reports code 0; the Intel installer log
ends with successful silent installation and internal exit code 0 (outer
self-extracting wrapper returned 1000). Secure Boot remains enabled.
An explicit DXGI enumeration and D3D11CreateDevice call targeting Intel
vendor 8086, device A780 succeeded: HRESULT 0, feature level 0xB000 (11.0).
Before persisting the host VFIO binding, cleanly stop the guest, create a
verified root snapshot and EFI recovery backup, then activate the already
built/tested /nix/store/ly2hfh2bmp7hfgs53464rcvad9njna7b-nixos-system-erebor-26.05.20261013.a033e66.
Retain generation 159 and the pre-IGD offline guest copies for recovery.
No second host reboot is needed for the current live test; early binding
must be rechecked at the next normal host boot. Verify a cold guest start
with the GPU still bound to vfio-pci before declaring guest passthrough done.

## [COMPLETED] Persist IOMMU configuration and reboot — 2026-10-18

User explicitly approved clean Windows shutdown, recovery snapshot, persistent
activation of the validated virtualization configuration, and host reboot.
Starting persistent recovery generation is 158. Before boot writes, verify
root/ESP UUIDs, shut down windows11 through its responsive guest agent, save
ESP and firmware state, and create/verify a read-only Btrfs root snapshot
(Snapper is not configured). Preserve firmware BootOrder/BootNext and other
operating systems' EFI files. Activate only the already built/tested system
at /tmp/windows-vm-system, excluding unrelated pending flake changes.
Do not reboot until the new generation, recovery entry, boot parameters,
EFI preservation and checkpoint have all been verified and recorded below.
Mandatory post-reboot checks: generation, mounts, failed units, libvirt,
intel_iommu=on, GPU IOMMU group, NVIDIA host driver, and Windows VM state.
Intel GPU remains on i915 until its isolation is verified.

Pre-boot recovery verified: Windows shut down cleanly through QEMU guest
agent. Read-only snapshot /btrfs-top/nixos-root-pre-iommu-20261018,
subvolume 646, UUID 090420ee-dd76-f04b-a8ad-8f76c1ed9f0a, ro=true.
Recovery archive /var/lib/windows-vm-recovery/pre-iommu-20261018/esp-before.tar
was listed successfully; directory also holds firmware state, generation 158
entry, Windows domain XML, and verified checksums of all Microsoft/Fedora/moria
EFI files. Recovery is selecting retained generation 158 from systemd-boot
(hold Space during boot); snapshot and ESP archive provide additional recovery.
Validated target is /nix/store/z2lfrlfggmpwd0b2nsb578lmdhyfk0b6-nixos-system-erebor-26.05.20261013.a033e66.

Final reboot checkpoint: persistent and active generation 159 is the validated
target above. Switch succeeded; nixos-generation-159.conf is the loader
default and includes intel_iommu=on iommu=pt. Generation 158 and its referenced
kernel/initrd remain available. Firmware before/after dumps are identical,
all Microsoft/Fedora/moria EFI checksums pass, and generation 158 entry is
byte-identical to its backup. Libvirt is active; no system/user units failed.
Windows remains shut down, with autostart disabled. No GPU binding changes.
Remaining risk: IOMMU enablement has not yet been tested at boot; if boot
fails, choose generation 158 by holding Space in systemd-boot. Mandatory next
action after reboot is verifying /proc/cmdline, generation 159, stable mounts,
failed units, libvirt, Intel GPU IOMMU isolation and NVIDIA driver before
resuming passthrough. Mac SSH approval forwarding may need reconnecting.

Post-reboot: booted generation 159, active/persistent store path matches the
checkpoint; /proc/cmdline includes intel_iommu=on iommu=pt. Root and ESP UUIDs
match expected values. Libvirt and default NAT network active; no system/user
units failed. Intel UHD 770 remains on i915 and is isolated in IOMMU group 0
with only 0000:00:02.0. RTX 4090 remains bound to nvidia. Windows was cleanly
shut off as expected (autostart disabled), then started for guest verification.
Firmware BootCurrent remains 0004; original BootOrder sequence preserved,
with 000B,000C,000D appended during reboot. No entries were removed or reordered
by this task; inspect the additional entries separately before changing them.
Windows guest-ping succeeded after boot; its SPICE console is again on
127.0.0.1:5900 and DHCP lease is 192.168.122.2.
IOMMU boot stage is verified; GPU binding and guest acceleration remain pending.

## [PENDING] Windows 11 VM with Intel GPU passthrough — 2026-10-18

User requested setup and selected a fresh Windows 11 guest in a Linux window.
Add modules/windows-vm.nix and its host import: libvirt/KVM, virt-manager,
TPM emulation, IOMMU kernel parameters, and windows-vm-create (8 vCPUs,
12 GiB RAM, sparse 120 GiB virtual disk, Secure Boot, local SPICE console).
Do not bind the Intel GPU until post-reboot IOMMU isolation and host render
usage are inspected. No physical guest disks are exposed. See WINDOWS_VM.md.

Preflight: active/persistent system generation 157,
/nix/store/hcdm0rmfk9jy24l58xvrr4r81h03hq2z-nixos-system-erebor-26.05.20261013.a033e66.
No failed system units. Root/home Btrfs UUID and ESP UUID match AGENTS.md.
Read-only firmware inspection: BootCurrent 0004, BootOrder
0004,0007,0002,0000,0008,0009,000A,0003; BootNext absent.
Btrfs currently has 35.54 GiB unallocated and metadata 2.60/6.50 GiB used.

Flake check, nixos-rebuild dry-build, and full system build passed using an
isolated copy of HEAD plus this module/import, excluding unrelated pending
Home Manager changes. Build: /tmp/windows-vm-system ->
/nix/store/4mmma92l817k0bxp8fhxnfh5pi6ky81m-nixos-system-erebor-26.05.20261013.a033e66.
Generated creation script passes the build's shell checks and usage check.
No activation, bootloader write, GPU unbinding, VM creation, or reboot yet.
sudo -n requires authentication; Mac approval socket is absent. Mandatory
next step: authenticate locally and test the built system, then verify libvirt
and NAT networking. Before any boot installation/reboot, create and verify a
recovery snapshot and update this checkpoint with the exact new generation.
Windows installation ISO is still required. Intel guest acceleration and
accelerated remote display remain unverified; SPICE is the install console.

Retry: Mac approval forwarding was restored. Rebuilt against current HEAD
to preserve the subsequently activated fish greeting; persistent recovery is
now generation 158, /nix/store/mphhdbrmlhiklpg178cjd5c7bhicmyr4-nixos-system-erebor-26.05.20261013.a033e66.
Flake check, dry-build, full build, and interactive-sudo test activation passed.
Live test system is /nix/store/z2lfrlfggmpwd0b2nsb578lmdhyfk0b6-nixos-system-erebor-26.05.20261013.a033e66.
Verified libvirtd active, KVM/device/cgroup checks pass, and default NAT network
active with autostart. No system or user units failed. Corrected creation
helper to use OVMFFull Microsoft-keyed firmware (default QEMU firmware lacks
enrolled keys), and declare /var/lib/libvirt/images via tmpfiles. The helper's
virt-install dry-run successfully generated installation and final XML with
Secure Boot firmware, SMM, TPM 2.0, and loopback SPICE; no VM or disk was created.
VirtIO ISO download completed. IOMMU still disabled in the running kernel,
as expected before reboot. No ESP/boot/profile changes or reboot performed.
Next: obtain Windows ISO, install guest, and prepare a verified recovery
snapshot/boot checkpoint before boot activation and IOMMU reboot.

Guest creation: located /home/janzon/Downloads/windows-vm/windws.is, a Polish
x64 Windows ISO. SHA-256 0eadddd47a6d6d4524df40cbd9b779c32df222f7d2000de2b82a000ca9c5470f
matches Microsoft's Polish x64 download table. Created persistent windows11
domain UUID 152dd897-6203-4cff-919c-bb38345c2dd0 using the installed helper.
Guest is running and screenshot verifies Windows Setup keyboard selection.
Only windows11.qcow2 (120 GiB virtual, initially 19 MiB allocated) and the
two installation CDs are attached. SPICE listens only at 127.0.0.1:5900.
Guest autostart remains disabled; system generation remains test-activated.
No janzon Linux GUI session is active. Open console locally with virt-viewer
or through qemu+ssh from a client with Virt Viewer. Installation, account setup,
guest drivers, persistent host activation and GPU passthrough are outstanding.

User completed Windows installation and virtio-win-guest-tools. Verified the
Windows desktop, running domain, and DHCP lease 192.168.122.2. Added missing
org.qemu.guest_agent.0 virtio Unix channel with --live --config; guest-ping
initially reported agent disconnected, then succeeded after hotplug detection
without a guest restart. Host remains on the validated test activation;
persistent IOMMU boot configuration and passthrough are still pending.

## [COMPLETED] Import Fedora fish greeting — 2026-10-18

Imported the captured Fedora moria banner, compact Fastfetch statistics, and
fortune cow into Home Manager with required packages and the slant font.
Preserved the cyan/purple gradient using a portable renderer. Replaced Fedora
DNF/nvm checks with Nix flake update guidance and the installed Node version.

Isolated flake check, full build, test activation, and persistent switch passed,
excluding unrelated pending changes. Reconnecting the Mac SSH forwarding
socket restored authentication; switch completed successfully. Verified the
deployed greeting with no stderr, no failed system/user units, expected root
and ESP UUIDs, and the generation 158 boot entry. Active and persistent system:
`/nix/store/mphhdbrmlhiklpg178cjd5c7bhicmyr4-nixos-system-erebor-26.05.20261013.a033e66`.
No reboot required.

## [PENDING] Bounded Btrfs data compaction — 2026-10-18

User explicitly authorized `sudo btrfs balance start -dusage=10,limit=2 /`.
Limit relocation to two data block groups at most 10% occupied; do not change
profiles, partitions, ESP, boot entries, or other filesystems. Existing verified
read-only root snapshot: /btrfs-top/nixos-root-pre-empty-block-cleanup-20261018
(subvolume 644, UUID 5def1c0f-9313-1a43-9d99-a64e893f335f).
Root filesystem UUID verified as 5be9be17-20c9-4a47-ba2d-6adf1ceb4c55.
Generation 156 remains active and available for recovery. After compaction,
inspect space and balance status, retry isolated eza checks/build, and verify
before activation. Mac authentication changes remain pending and inactive.

Both the approved 10%-usage/two-block command and a narrower 1%-usage/one-block
attempt failed with ENOSPC. No balance remains running; unallocated capacity
is still 1 MiB. No authentication/eza activation, profile conversion, file
deletion, or broader balance was performed. Further progress requires freeing
filesystem workspace before retrying. The recovery snapshot remains read-only.

## [COMPLETED] Check and reclaim empty Btrfs data blocks — 2026-10-18

User explicitly approved the proposed empty-block cleanup. Verify UUID
5be9be17-20c9-4a47-ba2d-6adf1ceb4c55 at / and /btrfs-top; create and verify
read-only snapshot /btrfs-top/nixos-root-pre-empty-block-cleanup-20261018.
Snapper is not installed. Recovery: generation 156 remains bootable and the
snapshot preserves the pre-operation NixOS root subvolume. No reboot, boot
entry, ESP, partition, profile conversion, or occupied-block relocation is
authorized. Run only btrfs balance start -dusage=0 /, inspect the result,
then retry the isolated eza build. Starting usage: metadata 6.00/6.50 GiB;
unallocated device capacity 1 MiB; estimated free data capacity 120.80 GiB.

Read-only root snapshot created and verified: subvolume 644, UUID
5def1c0f-9313-1a43-9d99-a64e893f335f, ro=true. The approved command exited 0:
"Done, had to relocate 0 out of 389 chunks". No empty data block groups were
available, so unallocated device capacity remains 1 MiB and the allocation
problem is unresolved. Root/ESP UUIDs and active system generation are
unchanged; no balance remains running. No occupied-block compaction was done.

## [PENDING] Install eza and Fish listing aliases — 2026-10-18

Add eza to Home Manager packages and aliases ls, ll, la, lla, and lt, with
directories first, automatic icons, and a two-level tree. Validate and activate
this change independently of the pending Mac authentication changes.

Downloaded eza 0.23.4 and verified the listing flags. The isolated source
copy excludes pending authentication changes. Flake check, system build,
and Home Manager-only build attempts failed with ENOSPC; no activation has
occurred. The retry after the approved empty-block cleanup still fails while
creating a Nix store lock file. Complete storage remediation and validation
before activation and committing the eza configuration. Nix daemon remains
active. Logrotate and a Podman healthcheck were already failed at preflight;
Nextcloud cron had also failed by the subsequent check.

## [COMPLETED] Mac Touch ID approval for sudo and Polkit — 2026-10-18

Enabled pam_rssh approval through Secretive's forwarded Mac agent for sudo
and Polkit, retaining Unix-password fallback. Removed Janzon's unrestricted
NOPASSWD rule. Public key remains locally provisioned, root:root 0644,
outside Git and the Nix store. Login/screen-lock PAM stacks are unchanged.
Polkit's sandbox hides home directories with ProtectHome=tmpfs and exposes
only OpenSSH's agent directory through a read-only bind.

The earlier Btrfs ENOSPC blocker is resolved. Isolated source excluded the
unrelated pending eza changes. Flake check, dry build, full build, test
activation, and persistent switch passed. Fresh sudo and Polkit checks
returned 0; user confirmed successful prompts required Touch ID. User also
confirmed explicitly cancelling a diagnostic Secretive prompt; the agent
rejected signing and PAM failed (exit 1). Sudo password fallback returned 0
after Mac cancellation, confirmed by the user. A disconnected agent also
fails the signature-only diagnostic. MAC_APPROVAL.md records reconnection
and the unprivileged pkttyagent workaround for upstream Polkit 127 issue
#686 (internal terminal agent fails with No session for cookie).

Active/persistent system and default boot entry are generation 157:
`/nix/store/hcdm0rmfk9jy24l58xvrr4r81h03hq2z-nixos-system-erebor-26.05.20261013.a033e66`.
Sudoers validates with no NOPASSWD; deployed sudo/Polkit PAM files match the
validated build. Polkit, Home Manager, sshd, and nix-daemon are active.
No failed system or user units at final verification. Root/ESP UUIDs retain
expected values; Windows/Fedora EFI hashes and all firmware entries are
unchanged. Generation 157's boot entry references the validated system and
existing kernel/initrd. No reboot performed or needed.

Recovery: generation 156 remains available. Verified read-only snapshot
`/btrfs-top/nixos-root-pre-mac-approval-persist-20261018`, subvolume 645,
UUID d3d11d92-73bb-1e42-a687-b45bb8345b34, ro=true. Reconnect the Mac's
forwarding session after disconnect/reboot to use Touch ID; Unix password
remains available. Pending eza configuration was neither activated nor
included in this commit.

## [COMPLETED] Install Fastfetch — 2026-10-17

Added `fastfetch` to Janzon's declarative Home Manager packages. Flake check,
build, test activation, and switch passed. Verified Fastfetch 2.63.1 runs and
reports OS, kernel, CPU, and memory. No failed system or user units; root and
ESP retain their expected UUIDs. Active system profile is generation 155:
`/nix/store/9vhh9mqpymhawqxg0g0n7d7syg54dgi6-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Cycle every matching application window — 2026-10-16

Right Ctrl+letter traverses all windows of matching apps, with Shift reversing
the same stable order. Sort by app name then window ID, so focus changes do
not reorder the cycle. Entering from another app initially focuses the most
recently used match. Preserve Alt's installed-app chooser and centering.

Algorithm checks covered three windows, reverse, wraparound, MRU entry, and
multiple apps. Flake check, dry build, test activation, and switch passed.
Full simulated Right Ctrl+H and Shift+Right Ctrl+H through xremap traversed
Helium windows 7 and 12 and wrapped in both directions with no new windows.
Active system is
`kkvxm8ilr0h480f9rhk021ihpf7w3wc9-nixos-system-erebor-26.05.20261013.a033e66`.
xremap and Vicinae are active, no failed system/user units, and root/ESP UUIDs
and the default boot entry remain correct. Live behavior verified in Niri.

## [COMPLETED] Always show the app chooser with Right Ctrl+Alt — 2026-10-16

Add Right Ctrl+Alt+A–Z and rcmd --choose to always open the installed-app list,
even when matching applications are running. Selecting an existing app focuses
and centers it; otherwise its desktop entry launches. Regular and Shift
cycling remain available.

Flake check, dry build, test activation, and switch passed. Full simulated
Right Ctrl+Alt+D through xremap opened the chooser with Discord/Dolphin running.
Escape created no windows; Enter focused existing Discord without duplication.
Ordinary Right Ctrl+D then cycled to Dolphin. Active system is
`pkzrm34hyxsi3ns2xz58di8vq9w6jc1m-nixos-system-erebor-26.05.20261013.a033e66`.
xremap/Vicinae are active; no failed system/user units. Root/ESP UUIDs and the
default boot entry remain correct. Live behavior verified in Niri.

## [COMPLETED] Cycle apps by initial with a Vicinae launch chooser — 2026-10-16

Right Ctrl+A–Z now cycles running apps by their desktop-entry display names;
Right Ctrl+Shift+A–Z cycles backward. Group windows by app and focus its most
recently used window, then center the column. With no matching running app,
Vicinae dmenu lists matching installed apps: Enter launches the selected
desktop entry and Escape cancels. Use Gio's desktop registry for IDs/names
and gio launch for desktop-entry semantics. New apps run in a separate user
systemd scope so restarting xremap does not terminate them. Per-letter locks
and a shared chooser lock prevent repeated presses stacking menus. The Polish
layout and Caps shortcuts remain intact. Former mnemonic shortcuts T/B/F are
replaced by actual app-name initials G/H/D.

Flake check, dry build, test activation, and switch passed. Algorithm checks
covered forward/reverse order across three apps, most-recent window selection,
accent normalization, and no matches. Live full chords through xremap cycled
Discord/Dolphin with D and Shift+D, and focused Ghostty/Helium/Spotify with
G/H/S. Z opened the chooser; Escape launched nothing; Enter launched and
focused Zed, which survived an xremap restart. Vicinae close/state IPC calls
can wait during its modal menu; validation used Niri layer visibility instead.
Active generation 150 is
`86ijc3svgcaahc5b1gcbgyarp08d9dr1-nixos-system-erebor-26.05.20261013.a033e66`.
xremap and Vicinae are active; no system/user units failed. Root/ESP UUIDs and
the default boot entry remain correct. Umbriel code is provided but live
behavior is only verified in Niri.

## [COMPLETED] Run all active Right Ctrl app helpers directly — 2026-10-16

Right Ctrl+T/B/F/S/D now directly launch the shared compositor-aware helper
for Ghostty, Helium, Dolphin, Spotify, and Discord. Preserve existing-window
focus, launch-if-missing behavior, and centering. Remove inactive Right Ctrl+Y,
the custom XKB rules/symbols and deployment, the moria:launchers option, and
obsolete app launcher bindings in Niri/Umbriel. Caps navigation is preserved.

Flake check, dry build, Niri/Umbriel validation, test activation, and persistent
switch passed. Full Right Ctrl sequences through a temporary keyboard grabbed
by xremap focused all five existing apps with no extra windows and no
intermediate launcher keys. After XKB removal and Niri reload, repeated all
five focus checks successfully. Both deployed custom XKB files are absent.
Active system is
`30wm6pcwgd210yms1q82b5jf20md88hn-nixos-system-erebor-26.05.20261013.a033e66`.
xremap is active; no failed system/user units. Root and ESP UUIDs and default
boot entry remain correct. Umbriel configuration validates; live routing
awaits an Umbriel session.

## [COMPLETED] Launch Spotify's focus helper directly from xremap — 2026-10-16

Right Ctrl+S now uses xremap launch instead of F18/XF86Music. A wrapper selects
the existing Niri/Umbriel helper by the active desktop and preserves centering.
Explicitly allow launching and give the user service both system and Home
Manager command paths. Other Right Ctrl shortcuts retain their key mappings
while this direct-launch approach is tried.

Flake check, dry build, test activation, and persistent switch passed. A full
Right Ctrl+S sequence through a temporary keyboard grabbed by xremap focused
Spotify, retained exactly one Spotify window, and emitted no F18 event.
After the service path expansion, the deployed wrapper also focused Spotify
with the exact service environment; all required commands including Umbriel
resolve. Active generation 148 is
`g5xamf0l2fpzhwkvk7jp0dfqkm1z32zr-nixos-system-erebor-26.05.20261013.a033e66`.
xremap is active; no system or user units failed. Root, ESP, and the default
boot entry remain correct. Umbriel routing is implemented but not live-tested.

## [COMPLETED] Use semantic Wayland launcher keys — 2026-10-16

Right Ctrl+T/F/S/D now emit XF86Terminal, XF86Explorer, XF86Music, and
XF86Messenger for Ghostty, Dolphin, Spotify, and Discord. Deploy an XKB option
through ~/.config/xkb/rules and symbols, preserving Polish typing and applying
the F15/F18 overrides after inet(evdev). This avoids relying on environment
variables unavailable to the running Wayland compositor. All four bindings
use focus-or-launch and center the focused column.

Compiled the deployed keymap, validated Niri and Umbriel, passed flake check,
dry build, test activation, and persistent switch. Live uinput events 185,
188, 430, and 144 focused Ghostty, Spotify, Discord, and Dolphin respectively.
Niri needed its keyboard options toggled once to discard the earlier cached
keymap. Active generation 147 is
`lc8y5hgwnrjzsav89d4vklp4dl3azrix-nixos-system-erebor-26.05.20261013.a033e66`.
xremap is active; there are no failed system or user units. Root and ESP UUIDs
and the default NixOS boot entry are correct. Umbriel's configuration and XKB
map validate; its live bindings await an Umbriel session.

After the user logged in again, the new Niri process loaded the user XKB
search path. Verified full Right Ctrl+T/S/F/D sequences through a temporary
keyboard grabbed by xremap, moving focus to another app before each check:
all four focused their intended apps. The previous running Niri context had
retained its startup include paths, so reloads alone could not enable the
new directory. The earlier output-only verification was insufficient.

## [COMPLETED] Accept the Fedora key name for Right Ctrl+S — 2026-10-16

Fedora's XKB layout reports xremap's F18 output as XF86Launch9. Bind both F18
and XF86Launch9 to the Spotify focus-or-launch helper in Niri and Umbriel.
Niri and Umbriel validation, `nix flake check`, dry build, test activation, and
persistent switch passed. Active generation is
`kmbyq6l3b612kz1cbpvyyn9ryx3fm73w-nixos-system-erebor-26.05.20261013.a033e66`.
Reloaded Niri and verified both deployed configurations contain the XF86Launch9
binding. xremap is active and there are no failed system or user units.

## [COMPLETED] Center Right Ctrl focus-or-launch windows — 2026-10-16

Center the focused column after each Right Ctrl app shortcut focuses or starts
Ghostty, Helium, Dolphin, or Spotify. Shell validation, `nix flake check`, dry
build, test activation, and persistent switch passed. Active generation is
`q6ai4zk2s8r126sh3iwfd151x1xn1a4r-nixos-system-erebor-26.05.20261013.a033e66`.
The live Niri helper focused Spotify window ID 38 and completed the center
column action. The xremap service is active, with no failed system or user
units.

## [COMPLETED] Restore Fedora focus-or-launch app shortcuts — 2026-10-16

Direct Right Ctrl app bindings spawn a new process and leave an existing window
unfocused. Restore Fedora's window lookup and focus behavior for Ghostty,
Helium, Dolphin, and Spotify in Niri and Umbriel. Niri and Umbriel validation,
`nix flake check`, dry build, test activation, and persistent switch passed.
Active generation is
`83iq53rcxzaa4wfyzlr1jp4yh93n1gcm-nixos-system-erebor-26.05.20261013.a033e66`.
Reloaded Niri's configuration and invoked the helper against its existing
Spotify window. It focused window ID 4 and retained one Spotify process. The
managed helper scripts and xremap service are active. The Umbriel helper uses
the same app-ID lookup and focus path; no Umbriel session was active to verify
live behavior.

## [COMPLETED] Bind Right Ctrl+S to Spotify — 2026-10-16

Right Ctrl+S is already remapped by xremap to F18, but neither compositor bound
F18. Bound it to Spotify in Niri and Umbriel. Niri and Umbriel configuration
validation, `nix flake check`, dry build, test activation, and persistent switch
passed. Active generation is
`9z1564c736d84xhdrii0i3aimn0818w6-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed Niri and Umbriel bindings and active xremap service confirm the
key sequence; launching Spotify forwarded to its existing instance. No system
or user units are failed, and the root, ESP, and default boot entry remain
healthy.

## [COMPLETED] Route HyperHDR music capture to the iFi output — 2026-10-16

HyperHDR's PipeWire ALSA input followed the default USB camera microphone,
which was muted, while Spotify played through the iFi USB output. Moving the
live stream to the iFi output monitor made HyperHDR report sound detected.
Added a PipeWire ALSA client stream rule to select that monitor when HyperHDR
starts. `nix flake check`, dry build, test activation, and persistent switch
passed. Active generation is
`28z1vlbfgj0pyx9pc49sayhn1gba9lsj-nixos-system-erebor-26.05.20261013.a033e66`.
After restarting WirePlumber and HyperHDR, the new music capture stream linked
to the iFi output monitor, HyperHDR reported sound detected, and the music
effect was visible at priority 1. The USB camera input was idle. HyperHDR and
WirePlumber are active, with no failed system or user units. Root and ESP mounts
and the NixOS boot entry remain healthy. The rule follows the iFi device; if
the playback device changes, update the selected monitor.

## [COMPLETED] Restore HyperHDR capture after graphical login — 2026-10-16

At 15:14 and 15:15, Niri session restarts caused the GNOME portal backend to
lose its Wayland connection. The portal frontend started just before the
backend, and HyperHDR then received ScreenCast version -1, fell back to X11,
and had no usable source. Order the frontend after the graphical session and
GNOME backend. Before HyperHDR starts, check the ScreenCast version; if it is
unavailable, queue a portal restart and let systemd retry HyperHDR. `nix flake
check`, `nixos-rebuild dry-build`, test activation, and persistent switch
passed. Active generation is
`1bngfw34ad4krsrjwkhn1q3zbfzl8zxp-nixos-system-erebor-26.05.20261013.a033e66`.
Verified the user-unit ordering, ScreenCast protocol v5, HyperHDR streaming a
3440x1440 display with zero service restarts, WLED on, unchanged root and ESP
mounts and boot entries, and no failed system or user units. A future Niri
login has not yet exercised the recovery path.

## [COMPLETED] Enable Ghostty background blur in Niri — 2026-10-16

Add a Ghostty-specific Niri background-effect rule. `nix flake check` and
`nixos-rebuild dry-build` passed; `nixos-rebuild switch` activated generation
`fnbjkq4kbhbg5vqv8m4j87qz16lk1kqn-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed configuration includes the rule, and `niri msg action
load-config-file` succeeded. `niri msg windows` confirms Ghostty is running
with app ID `com.mitchellh.ghostty`, matching the rule.

## [PENDING] Start Umbriel on the ordinary workspace — 2026-10-16

Enable Umbriel's leading empty workspace and add a startup helper that moves
the persistent `background-apps` workspace after ordinary workspaces, then
focuses workspace 1. This makes normal app launches start on the ordinary
workspace. Umbriel config validation, `nix flake check`, and dry build passed.
`nixos-rebuild switch` activated generation
`ahgjmy2v1mccrrfxs2f5alfb4bp0kbfn-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed config validates. No Umbriel socket is available for live
verification; verify the startup workspace order and app launch placement in a
fresh Umbriel session.

## [PENDING] Start Niri on the ordinary workspace — 2026-10-16

Run the background workspace reorder helper with a startup-only option that
focuses Niri workspace 1 after placing `background-apps` last. The existing
Caps+Q invocation does not pass the option, so it retains its current focus
behavior. `niri validate`, `nix flake check`, and dry build passed. The change
is activated in generation
`rz7jf0lk7fgrsm8v81635pr5ixmvqbby-nixos-system-erebor-26.05.20261013.a033e66`;
the deployed config validates. `niri msg action load-config-file` could not
connect because no Niri socket is available. Verify the startup workspace and
app launch placement in a fresh Niri session.

## [PENDING] Bind Right Ctrl+D to Discord and widen Niri tab indicators — 2026-10-16

Map Right Ctrl+D to `KEY_PROG4` in xremap and bind `XF86Launch4` to spawn
Discord in Niri and Umbriel. Increase Niri's tab-indicator width to 8 logical
pixels. Niri and Umbriel config validation, `nix flake check`, and dry build
passed. Activated generation
`2grjk9jkykfqfmv81c3vcjsx7vm2xdl5-nixos-system-erebor-26.05.20261013.a033e66`;
the deployed configs validate and the Niri config reload succeeded. Directly
spawning `discord` through Niri opened its window. xremap cannot currently find
any configured keyboard device and its service is failed, so Right Ctrl+D is
not yet verified. Reconnect a configured keyboard, confirm xremap is active,
then verify the shortcut and tab indicator.

Record completed NixOS configuration changes and material pending operations
here. Prefix active work **[PENDING]**; change that entry to **[COMPLETED]**,
**[BLOCKED]**, or **[CANCELLED]** with its final result. Do not record
secrets, routine read-only inspections, or one-off command failures.

## [COMPLETED] Make KDE applications follow Noctalia theme changes — 2026-10-16

Use KDE's Qt platform integration and Noctalia's generated KColorScheme for
Dolphin, Gwenview, and other Qt applications. Removed the fixed qt6ct palette
override and Qt6ct template, and configured both Umbriel and Niri to set
`QT_QPA_PLATFORMTHEME=kde`. Umbriel and Niri config validation, `nix flake
check`, dry build, test activation, and persistent switch passed. Verified the
deployed session configuration and user manager environment select KDE's
platform integration; active generation is
`f5l2b7slrm4954w53by3inj0r6bs15is-nixos-system-erebor-26.05.20261013.a033e66`.
The already-running Umbriel process retains its previous environment; a fresh
Umbriel login and reopening Dolphin/Gwenview are required to verify their live
appearance.

## [COMPLETED] Adjust Ghostty background opacity — 2026-10-16

Change the Home Manager Ghostty setting from `background-opacity = 0.8` to
`background-opacity = 0.75`. `nix flake check` and dry build passed; test
activation and persistent switch succeeded. Verified the deployed config and
`ghostty +show-config` report opacity 0.75. Active generation is
`myh9qf2a7bji0hillyz3kjpjz36s160p-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Set Ghostty background opacity — 2026-10-16

Manage Ghostty's existing Noctalia theme and set `background-opacity = 0.8`
through Home Manager. `nix flake check` and `nixos-rebuild dry-build` passed;
test activation and persistent switch succeeded. Verified the deployed file
is Home Manager-managed and `ghostty +show-config` reports the Noctalia theme
and opacity 0.8. Active generation is
`bn2kyy49nl5yyp82vrhcc6hnbq44gza1-nixos-system-erebor-26.05.20261013.a033e66`.

## [PENDING] Add Umbriel as a second Wayland session — 2026-10-16

Added the Umbriel NixOS and Home Manager modules and a tuigreet session menu
for Niri and Umbriel. Ported Niri's application shortcuts, CapsLock/xremap
navigation and window chords, workspace controls, layout and sizing shortcuts,
media controls, and screenshots to Umbriel actions. Added Umbriel-aware helpers
for the Discord/Spotify background workspace and focused-window screenshots.
Configured Umbriel's connected `DP-1` output to match Niri's native
3440×1440@164.899994 Hz mode and enabled HDR continuously on that output.
`nix flake check`, dry build, test activation, and persistent switch succeeded;
the active generation is
`h97j70h281gdfciy4wsw62v6nbrbnidd-nixos-system-erebor-26.05.20261013.a033e66`.
Both source and deployed Umbriel configs pass `umbriel config validate`. Live
Umbriel inspection reports `hdr_mode: on`, `hdr_active: true`, PQ output, and
the configured 3440×1440@164.9 Hz mode on DP-1. No system units are failed.
The locked Umbriel flake uses its own Nixpkgs revision because this system's
26.05 pin only provides wlroots 0.20.0 while Umbriel requires at least 0.20.1.
The running greetd process still has its previous config because restarting it
would end the active graphical login. Next action: restart greetd after the
user approves ending the current graphical session, verify both sessions
appear in the chooser, and complete this entry.

## [COMPLETED] Add UT2004 runaway-loop launch option — 2026-10-16

Mirrored the Fedora per-user UT2004 desktop entry's `-norunaway` argument in
the NixOS-managed desktop entry. The OldUnreal installer workaround
`MainMenuClass=GUI2K4.UT2K4MainMenuWS` was already active in the user's UT2004
configuration. `nix flake check` and `nixos-rebuild dry-build` passed; switch
activated generation 123. Verified the deployed desktop entry contains
`Exec=ut2004 -norunaway`; Home Manager activation succeeded and no system units
are failed.

## [COMPLETED] Add Cockpit at sys.erebor.jzon.pl — 2026-10-16

Enabled the NixOS Cockpit service and proxied `sys.erebor.jzon.pl` through
Caddy. Port 9090 remains closed in the host firewall; Cockpit accepts the
configured HTTPS/WSS origin and forwarded protocol from Caddy. Added a system
link to the service index. `nix flake check`, dry build, test activation, and
switch passed; generation 122 is active. Verified `cockpit.socket` and Caddy
are active and the URL returns HTTP 200 with trusted TLS. No failed units and
no reboot needed.

## [COMPLETED] Add OVH-backed HTTPS aliases for erebor — 2026-10-16

Set the machine hostname to `erebor` and retained `moria` as an alias. Built
Caddy with the OVH DNS provider and reused Fedora's credentials from
`/etc/caddy/ovh.env` (root-only, outside the Nix store and repository). Added
`erebor` A records at `100.108.216.80`, the current Tailscale address. Restored
the `moria` and wildcard A records to Fedora's Tailscale address,
`100.98.112.118`, after initially pointing them at this host. Caddy now serves
cloud, media, sync, torrent, and code under both names with DNS-01 HTTPS; chat
and the unsupported dashboard were omitted. Added `cloud.erebor.jzon.pl` to
Nextcloud's trusted domains. The Fedora source remains mounted read-only at `/mnt/fedora-*`.
`nix flake check`, dry build, test activation, and switch passed; generation 121
is active. Verified trusted HTTPS certificates and expected responses for both
root names and all ten service aliases. No system units are failed and no reboot
was needed.

## [COMPLETED] Force Darkly Qt style in user sessions — 2026-10-16

Set Home Manager's `QT_STYLE_OVERRIDE=Darkly` so Qt applications use the
Darkly style. `nix flake check` and `nixos-rebuild dry-build` passed; the
configuration is active as generation
`4qh5pc4x4gfpvh2pb6xr67w3jv4pqsa5-nixos-system-moria-26.05.20261013.a033e66`.
Verified the generated Home Manager session environment exports the override.
After a fresh graphical login, verified Qt applications launched from Niri
use Darkly with the configured style options.

## [COMPLETED] Add local service hostnames — 2026-10-16

Added loopback host entries and Caddy host routing for `torrent`, `jellyfin`,
`nextcloud`, and `syncthing`, each with a `.localhost` form. Added both
Nextcloud aliases to the shared trusted domains. Existing LAN links and ports
remain available. `nix flake check`, dry build, and activation passed;
generation 109 is active. Verified all eight names resolve to `127.0.0.1` and
each hostname routes to its service. No system units are failed.

## [COMPLETED] Proxy local qBittorrent hostnames safely — 2026-10-16

Kept qBittorrent's existing single allowed server domain and host-header
validation. NixOS Caddy proxies local aliases with the canonical
Host/Origin/Referer and strips browser HTTP Basic Authorization, matching
Fedora's proxy. The shared profile retains its original single domain. The
pre-change recovery point is read-only snapshot
`/btrfs-top/srv-pre-shared-services-20261016`. `nix flake check`, dry build,
and switch passed; generation 111 is active. Both local aliases and the
canonical domain return HTTP 200, including a request carrying a stale Basic
Authorization header. qBittorrent remains active with its normal login, and
no system units are failed.

## [COMPLETED] Share Fedora service state with NixOS — 2026-10-16

Created and verified read-only snapshot `/btrfs-top/srv-pre-shared-services-20261016`
(UUID `29e40720-ff44-034c-8d5f-32af4482ff28`, subvolume ID 643) before changes.
The source is Fedora's `srv` Btrfs subvolume. NixOS now uses Fedora's service
state directories for Jellyfin, Nextcloud, Syncthing, and qBittorrent;
qBittorrent writes downloads to the shared `/srv/torrents` path. Media-library
and external-drive mounts remain read-only inside Jellyfin/Nextcloud, and the
NixOS-local copies remain available as rollback data. The same service must
not run on both operating systems at once. NixOS generation 108 is active;
`nix flake check` and `nixos-rebuild dry-build` passed. The switch's first
Jellyfin health check raced container startup, but Jellyfin subsequently
reported healthy and the transient failed unit was cleared; no units are now
failed. All four services are active, Nextcloud reports no DB upgrade pending,
and the local service endpoints return their expected responses. Verified
qBittorrent's shared profile and downloads are writable, while its external
drives and the Jellyfin/Nextcloud media binds remain read only. Added the
NixOS-local Nextcloud hostname to shared trusted domains and allowed the
NixOS Podman proxy range. The snapshot is retained; the previous NixOS-local
copies remain available. No reboot was performed.

## [COMPLETED] Import Fedora service mounts and local services — 2026-10-16

Checkpoint before mount/service changes: generation 100 is active on the
`nixos-root` Btrfs subvolume; `/home` is `nixos-home`; `/boot` is the NixOS
ESP. Fedora and Windows UEFI entries were present. Created and verified read-only Btrfs
snapshot `/btrfs-top/nixos-root-pre-service-import-20261016` (UUID
`be74b8ca-fe02-b440-8863-21c3890650dd`, subvolume ID 642). Kept Fedora's
`/srv` and external-drive data read-only on NixOS. Generation 107 is now the
active default; all five mounts are read-only, all imported services and Caddy are
active, service endpoints
respond as expected, and no system units have failed. Generation 100 remains
in the boot menu for recovery. Fedora and Windows boot entries remain
available. No reboot was performed.

## [COMPLETED] Mount Fedora service volumes read-only — 2026-10-16

Mounted Fedora's `srv` Btrfs subvolume at `/srv` and all four external drives
at Fedora's `/srv/external/*` paths, with read-only mounts and automounts.
BigDaddy uses its existing private unlock key and a read-only LUKS mapping.
Expansion was unmounted from its desktop mount before the managed read-only
mount was activated. The flake check, dry build, test activation, and
persistent switch passed. Generation 101 is active; all five mounts are
verified read-only, no system units are failed, and generation 100 remains in
the boot menu as recovery.

## [COMPLETED] Enable Steam — 2026-10-16

Enabled the NixOS Steam module with scoped unfree package allowances. The
flake check, dry build, test activation, and persistent switch passed. The
active system contains `steam`, 32-bit graphics support is enabled, and no
system units are failed.

## [COMPLETED] Install Stremio Linux shell — 2026-10-16

Added the current `stremio-linux-shell` package and its scoped unfree allowance.
The flake check and dry build passed. The local source build, test activation,
and persistent switch succeeded. The active system contains `stremio`, and no
system units are failed.

## [COMPLETED] Install Haruna video player — 2026-10-16

Added Haruna as a graphical video player alongside the existing mpv package.
The flake check, dry build, test activation, and persistent switch passed.
The active system contains `haruna`, and no system units are failed.

## [COMPLETED] Install Ark — 2026-10-16

Added Ark as a system package. The flake check and dry build passed, then test
activation and persistent switch succeeded. The active system contains `ark`,
and no system units are failed.

## [COMPLETED] Install Okular — 2026-10-16

Added Okular as a system package. The flake check and dry build passed, then
test activation and persistent switch succeeded. The active system contains
`okular`, and no system units are failed.

## [COMPLETED] Restore Dolphin Open With applications — 2026-10-15T18:10:29Z

Added a small freedesktop applications menu for the Niri session so KDE's
service cache can discover installed desktop entries. The flake check, dry
build, test activation, and persistent switch passed; generation 74 is active.
Rebuilt the KDE service cache and verified it lists 20 applications, including
Zed, mpv, Helium, and Chromium. The menu is deployed, mounts are unchanged,
and no system or user units are failed. The Dolphin GUI was not opened during
verification.

## [COMPLETED] Use wheel for UDisks system data mounts — 2026-10-15T18:08:04Z

Replaced the dedicated `storage` group with `wheel` for the UDisks system data
mount rule and removed `storage` from the user configuration. The flake check,
dry build, test activation, and persistent switch passed; generation 73 is
active. A `wheel` session without `storage` passed the mount authorization
check. UDisks and Polkit are active, existing mounts are unchanged, and no
units are failed. No drive was mounted or unmounted during verification.

## [COMPLETED] Scope power actions to the wheel group — 2026-10-15T18:04:57Z

Replaced the user-specific Polkit power rule with a `wheel` group check. The
flake check, dry build, test activation, and persistent switch passed;
generation 72 is active. Authorization checks against Noctalia's process
passed for all six actions after activation. Polkit and Noctalia are active,
mounts are unchanged, and no units are failed. No power action was executed.

## [COMPLETED] Allow janzon to reboot, shut down, and suspend — 2026-10-15T18:02:04Z

Added a Polkit rule for the normal logind power actions, including the
multiple-session variants used while SSH is connected. The flake check, dry
build, test activation, and persistent switch passed; generation 71 is active.
Authorization checks against Noctalia's process succeeded for all six actions.
Polkit and Noctalia are active, and no system or user units are failed. No
power action was executed during verification.

## [COMPLETED] Move the Noctalia dock to the left — 2026-10-15T17:52:58Z

Set the managed Noctalia dock position to `left`. `nix flake check`, the
NixOS dry build, test activation, and persistent switch passed. Reloaded the
Noctalia configuration and dock successfully; the deployed configuration
contains `position = "left"` and Noctalia reports its bar visible.

## [COMPLETED] Preserve Lyrics-only bar choice and add cache repair — 2026-10-15T17:50:01Z

The live Noctalia bar no longer includes `media_lyrics`; removed it from the
managed bar layout while retaining the plugin. Added `make
repair-noctalia-lyrics` to recreate the first Lyrics plugin's temporary request
directory and reload Noctalia after plugin updates. The repair action,
`nix flake check`, dry build, test activation, config validation, and persistent
switch passed. Verified the effective bar retains `lyrics_2` but not
`media_lyrics`, Noctalia is active, and no system units are failed. Existing
unrelated Noctalia validation warnings remain.

## [COMPLETED] Show both Noctalia lyrics plugins on the bar — 2026-10-15T17:43:32Z

Added the existing `h465855hgg/lyrics` widget and the enabled
`tranzem/media-lyrics` now-playing widget to the bar, with inline lyrics
enabled for Media Lyrics. Updated the live bar override while preserving its
unrelated settings. `nix flake check`, dry build, test activation, Noctalia
config validation, and persistent switch passed. Verified both widget types in
the effective configuration, Noctalia active with its bar visible, and no
failed system units. Noctalia validation still reports unrelated pre-existing
warnings for the generated Starship file and disabled `mango-displays` widget.

## [COMPLETED] Start the Noctalia Spotify lyrics daemon — 2026-10-15T19:35:00Z

The active bar entries use `goatnath/spotify-lyrics`, whose widget reads
`~/.cache/noctalia/lyrics/current.json` from a separate Python daemon. Add a
graphical-session user service for that daemon with the existing packaged
Python `syncedlyrics` environment and `playerctl`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed; a live `test`
activation produced current-track lyrics before `switch` made the service
persistent. Verified the service is enabled and running, its state file updates
continuously with real lyric lines, and no units are failed.

## [COMPLETED] Start Vicinae with Niri and bind launcher shortcuts — 2026-10-15T17:10:00Z

Enable Vicinae's packaged user service through the graphical-session target.
Bind Caps+Space (translated by xremap), Super+Space, and Alt+Space to toggle
Vicinae from Niri. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation;
the configuration was activated successfully. Verified the service is enabled
and running, and all three bindings are deployed. No failed units remain.

## [COMPLETED] Fix Vicinae user-service executable lookup — 2026-10-15T19:20:00Z

Override the packaged user service's bare `vicinae` command with the absolute
executable path from the pinned Vicinae package; the user service manager could
not resolve the command from its environment, causing repeated `203/EXEC`
restarts. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed before activation; the configuration was activated
successfully. Verified the service drop-in uses the absolute package path and
Vicinae is active and running (PID 797905); no failed user units remain.

## [COMPLETED] Bind Caps+O to Vicinae Spotify search — 2026-10-15T19:25:00Z

Use the existing xremap Caps layer chord to invoke the installed Spotify
Raycast extension's `search` command directly from Niri. `niri validate`,
`nix flake check`, and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed before activation; the configuration was activated successfully.
Verified the deployed binding targets the loaded
`@mattisssa/store.raycast.spotify-player:search` command.

## [COMPLETED] Pin Vicinae to its upstream Nix flake — 2026-10-15T17:05:00Z

Replace Nixpkgs’ Vicinae v0.23.2 with the upstream flake’s v0.29.1 package,
without changing the system-wide Nixpkgs pin. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation;
the configuration was activated successfully. The upstream closure required a
771 MiB download (1.6 GiB unpacked) because it uses a newer independent
Qt/Node stack. Verified the active system runs Vicinae v0.29.1 and no units
are failed.

## [COMPLETED] Install Vicinae launcher — 2026-10-15T17:02:00Z

Add the packaged Vicinae application launcher to the declarative system
package set. No launcher binding or additional service configuration is added.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed before activation; Vicinae v0.23.2 and its desktop entries are present
after activation, with no failed system units.

## [COMPLETED] Make Starship follow Noctalia’s active palette — 2026-10-15T17:00:00Z

Use Noctalia’s built-in Starship template to generate a runtime palette while
keeping the custom prompt as a declarative base. Export `STARSHIP_CONFIG` to
both Fish and Niri-launched programs, and maintain a writable generated
Starship configuration for Noctalia to update when its palette changes.
`niri validate`, `nix flake check`, and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed before activation; the configuration was activated
successfully with no failed units. Verified Fish and a Niri-spawned process
use the writable runtime config, which selects the `noctalia` palette and
contains the generated Flexoki palette block.

## [COMPLETED] Make Niri follow Noctalia’s active palette — 2026-10-15T16:54:07Z

Include Noctalia’s generated Niri palette after the managed compositor
configuration, allowing Noctalia to set focus-ring, border, tab-indicator,
insert-hint, and recent-window highlight colors whenever its palette changes.
`niri validate`, `nix flake check`, and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed before activation; the configuration was activated
successfully with no failed units. Niri automatically reloads changed
configuration, so no compositor restart or logout is required. Verified the
managed configuration includes the active generated palette, whose current
focus color is Noctalia’s Flexoki primary `#879a39`.

## [COMPLETED] Align Dolphin, Noctalia, and apps with shared desktop themes — 2026-10-15T18:45:00Z

Keep the Darkly Qt widget style, but make Qt6ct use Noctalia's existing
generated `noctalia.conf` palette. Keep Noctalia's `qt` and `kcolorscheme`
templates enabled: the former supplies the Qt palette and the latter supplies
the KDE color scheme used by Dolphin. Ensure applications spawned by Niri
receive `QT_QPA_PLATFORMTHEME=qt6ct`, and reset Dolphin's per-application
scheme override to follow the active KDE palette.

Install the Candy icon theme system-wide and select it through GTK and KDE's
standard preferences, making it available to Noctalia, Dolphin, and other
toolkit-native applications. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation;
the configuration was activated successfully. Verified Qt6ct now selects
Noctalia's generated palette while retaining the Darkly widget style,
Dolphin follows the shared KDE color scheme, GTK and KDE select
`candy-icons`, and Noctalia's Niri-spawned process environment contains
`QT_QPA_PLATFORMTHEME=qt6ct`. No failed system units remain.

## [COMPLETED] Permit regular-user mounting of data disks — 2026-10-15T10:30:00Z

Allow members of the dedicated `storage` group to mount UDisks-classified
system data devices without a password, so access can be managed by group
membership rather than a user-specific Polkit rule. Add `janzon` to that
group. Do not grant permissions to format, partition, or otherwise administer
disks. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed, then the configuration was activated. Verified a
fresh `janzon` process has the `storage` group and can mount `/dev/sdb1` at
`/run/media/janzon/Expansion` and unmount it without sudo or a password; zero
units are failed. Existing desktop processes require a logout/login to receive
the new supplementary group.

## [COMPLETED] Import and repair OldUnreal UT2004 from GoodRam — 2026-10-15T20:20:33+02:00

Imported the OldUnreal UT2004 3374 RPM from the mounted GoodRam SSD into
`~/Games/UT2004`, leaving the source unchanged. The Fedora-built game required
the legacy `libomp.so.5` loader name plus the C++ and OpenGL GLVND runtimes.
The declarative launcher now provides these libraries. `nix flake check`,
`nixos-rebuild dry-build --flake /etc/nixos#moria`, and `nixos-rebuild switch`
passed. A 15-second windowed, soundless launch smoke test resolved the game and
renderer dependencies, began the first-run content export, and remained running
until the intentional timeout.

## [COMPLETED] Set Niri refresh rate and disable Mango Displays — 2026-10-15T14:52:48Z

Configured DP-1 declaratively for 3440x1440 at 164.899994 Hz in the managed
Niri configuration. Disabled the Mango Displays plugin, which writes MangoWM
rules and cannot apply display settings under Niri. Niri config validation,
`nix flake check`, dry build, and switch passed. Verified the active Niri
output reports 3440x1440 at 164.900 Hz and the plugin remains disabled.

## [COMPLETED] Add Noctalia Processes dependencies and wlr-randr — 2026-10-15T14:50:11Z

Added `psutil` and Pillow to the dedicated Noctalia plugin Python environment,
and added `wlr-randr` to the system packages. `nix flake check`, dry build,
and switch passed. Verified Python imports `psutil 7.2.2` and `Pillow 12.3.0`,
the Processes plugin statistics script starts successfully, `wlr-randr --help`
works, and `noctalia.service` remains active.

## [COMPLETED] Restore Fedora Noctalia layout and appearance settings — 2026-10-15T14:46:50Z

Restored the saved Fedora bar layout and sizing, taskbar and widget tuning,
Flexoki dark community theme, theme templates, launcher pin, and panel anchor
to the declarative Noctalia configuration. Retained the explicitly requested
top dock instead of Fedora's saved left dock. Kept the unavailable Mango
Displays widget and the two display plugins excluded pending compatibility
work. `nix flake check`, NixOS dry build, and switch passed; the active
Noctalia configuration reloaded and its service is active. The existing
Spotify-media validation warning remains unrelated.

## [COMPLETED] Match Noctalia bar and dock placement to Fedora — 2026-10-15T14:44:17Z

Made the managed Noctalia edges explicit: the default bar is on the bottom and
the dock is on the top, matching Fedora instead of Noctalia's implicit default
layout. `nix flake check`, `nixos-rebuild dry-build`, and
`nixos-rebuild switch --flake /etc/nixos#moria` completed successfully. Reloaded
the active Noctalia configuration; it validates and `noctalia.service` remains
active. The pre-existing Spotify media plugin validation warning remains
unrelated to these placement settings.

## [COMPLETED] Adapt Spotify Media plugin for Niri — 2026-10-15T14:05:49Z

Published the standalone Noctalia plugin fork at
`https://github.com/question44/spotify-media-niri` (commit `9eb7314`). Replaced
Hyprland window detection and focus with Niri window listing and
`focus-window`, retaining Spotify MPRIS metadata, controls, artwork, and launch
behavior. Added the Git source to Noctalia and updated the managed bar config
to use the fork; disabled the original Hyprland-specific community plugin.
Noctalia plugin lint passed with zero errors and warnings, as did `nix flake
check` and the NixOS dry build. Test activation and switch completed on
generation 48. Verified the fork is enabled, the Noctalia service is active,
Spotify's Niri `app_id` is `spotify`, the Niri focus action focuses its window,
Playerctl reads its MPRIS state, and no system units are failed.

## [COMPLETED] Install Noctalia plugin dependencies — 2026-10-15T13:20:42Z

Added the available dependencies declared by enabled Noctalia plugin manifests
to the NixOS package set, including Python plugin modules, Screen Toolkit tools,
PipeWire development metadata, and packaged `ai-usagebar` and NCS renderer
binaries. Kept Hyprland and `hyprctl` excluded as requested; Hyprland-specific
plugin actions remain unavailable. Nix flake check, dry build, test activation,
and persistent activation passed. Verified the mapped plugin commands are on
the session PATH, GTK3 and GtkLayerShell import through Python, PipeWire is
discoverable by pkg-config, Noctalia config validates and its service is active
on `system-47-link`; no system units are failed.

## [COMPLETED] Migrate Noctalia configuration from Fedora — 2026-10-15T12:37:43Z

Imported Fedora's Noctalia v5 configuration through Home Manager, copied its
29 enabled plugin repositories and two referenced wallpapers into NixOS user
state, and preserved the existing NixOS GUI overrides. Kept a backup of the
previous NixOS plugin tree; the Fedora source remains untouched. `nix flake
check`, dry build, test activation, and persistent activation passed. Noctalia
config validation passes and its user service is active on `system-46-link`.
Two migrated plugins log repeated missing-setting warnings (`ncs-visualizer`
and `pixel-shift`); the overall Noctalia config remains valid.

## [COMPLETED] Install Zed and configure LazyVim — 2026-10-15T11:55:58Z

Installed Zed 1.3.6 and Neovim 0.12.4 for `janzon` through Home Manager and
deployed the official LazyVim starter configuration. The terminal `EDITOR`,
`VISUAL`, and `GIT_EDITOR` use a managed wrapper that selects Zed when the
Wayland socket or X display is available and Neovim otherwise; both paths were
verified. Zed remains the XDG handler for `text/plain`. LazyVim stores its
generated plugin lockfile in writable Neovim state because the Nix managed
config is read only. `nix flake check`, the NixOS dry build, test activation,
and persistent activation passed. Verified the headless LazyVim startup with
plugins loaded and persisted generation `system-45-link`; no system units are
failed.

## [COMPLETED] Bootstrap Codex CLI with npm — 2026-10-15T08:16:38Z

Replace the persistent bootstrap service with an explicit `make setup-codex`
target. It uses Nix-managed Node.js to install `@openai/codex@latest` into
`/home/janzon/.local` only if Codex is absent. Add `make help` to list the
available maintenance targets. The existing standalone Codex installation must
remain untouched and T3 Code must remain active. `make help` lists the four
available actions and `make setup-codex` correctly preserved the existing
Codex executable. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed, then the configuration was activated. Verified the
bootstrap user service is removed, T3 Code remains active, and zero units are
failed.

## [COMPLETED] Restore Fedora Starship prompt — 2026-10-15T08:08:00Z

Restored the complete Fedora Starship prompt configuration for `janzon` and
enabled its Fish integration declaratively through Home Manager. `nix flake
check` and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
Home Manager configuration was activated. Verified Starship 1.25.1 is present,
a fresh Fish shell loads Starship's `fish_prompt`, and its success symbol
renders as configured. Home Manager canonically rewrites the TOML, but it uses
the full recovered Fedora settings; zero system units are failed.

## [COMPLETED] Add T3 Code pairing alias — 2026-10-15T08:04:55Z

Added the managed Fish alias `t3pair`, which runs
`t3 pair --base-dir /home/janzon/.t3/server` against the native T3 Code
service. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed, then the Home Manager configuration was activated.
Verified a new interactive Fish shell defines `t3pair` with the expected
arguments and its T3 help output succeeds; zero system units are failed. The
prior unmanaged Fish configuration was preserved as `config.fish.backup`.

## [COMPLETED] Add native T3 Code and LAN Caddy index — 2026-10-15T07:56:42Z

Installed the supported T3 Code CLI 0.0.45 for `janzon` and enabled
`programs.nix-ld` because its official generic Linux binary requires NixOS's
compatibility loader. Added a persistent native `t3code.service` user service
using `/home/janzon/Projects` as its working directory, with the existing
`/home/janzon/.local/bin/codex` on its runtime `PATH`. Caddy serves the
minimal service index on LAN TCP 80 and proxies T3 Code on LAN TCP 8080; the
T3 backend itself is bound only to `127.0.0.1:3773`. No Tailscale route or
other former Fedora service was added. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
configuration was activated. Verified both services are enabled and active,
the index and proxy return HTTP 200 through the LAN address, TCP 80 and 8080
are accepted only on `enp4s0`, T3 Code is ready, Codex 0.162.1 resolves from
the T3 service environment, and zero system units are failed.

## [COMPLETED] Create XDG user directories — 2026-10-15T09:45:00Z

Enabled Home Manager's XDG user-directory management for `janzon`, creating
the standard user directories and the `Projects` directory declaratively.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed. Activated generation
`3kd4x7rg1dab252b7hxj87ajgapcyvb5-nixos-system-moria-26.05.20261013.a033e66`.
Verified all nine directories, the managed `~/.config/user-dirs.dirs` mappings
(including `XDG_PROJECTS_DIR`), an active `home-manager-janzon.service`, and
no failed system units.

## [PENDING] Add encrypted Tailscale state backup workflow — 2026-10-15T09:35:00Z

At the user's explicit request, make a password-encrypted archive of
`/var/lib/tailscale` suitable for Git tracking, despite the repository's
usual prohibition on private-key material. Add declarative GnuPG support and
Make targets to create and restore the archive. The backup password is entered
interactively and must never be recorded in the repository or Nix store.

## [COMPLETED] Rename Tailscale node to erebor — 2026-10-15T09:28:00Z

Changed the connected Tailscale device hostname from `moria-1` to `erebor`
using its local persistent preference. Verified the control plane reports
`erebor` at `100.108.216.80` and `tailscaled` remains active. The NixOS host
name remains `moria`.

## [COMPLETED] Install and configure Tailscale — 2026-10-15T02:35:00Z

Enabled the NixOS Tailscale service declaratively, without an auth key or
special routing configuration. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`7zg9wpkl4w2n4dwrpzihyhh6bjzhcf7q-nixos-system-moria-26.05.20261013.a033e66`.
Verified `tailscaled` is enabled and active, and interactive authentication
joined this device as `moria-1` with Tailscale address `100.108.216.80`. The
root-only persistent state is held outside the Nix store at
`/var/lib/tailscale/tailscaled.state`; no secret is committed to this repository.

## [COMPLETED] Fix qt6ct Darkly palette and remove forced style override — 2026-10-15T01:15:00Z

Stopped setting Home Manager `QT_STYLE_OVERRIDE`; retained the Darkly Qt 6
plugin package and plugin-path setup. Added a qt6ct-format Darkly palette and
managed qt6ct's style/palette selection declaratively. `nix flake check` and
the full system build passed. Activated generation
`g3ba9l71qc5bf6l08id376pj4njx44ma-nixos-system-moria-26.05.20261013.a033e66`.
Verified generated `qt6ct.conf` selects Darkly and the managed palette, and the
user manager no longer exports `QT_STYLE_OVERRIDE`. The previous GUI-managed
configuration is preserved at `~/.config/qt6ct/qt6ct.conf.backup`. The running
Niri process retains its old environment; a fresh graphical login is needed
before it stops exporting the removed override to newly launched applications.

## [COMPLETED] Expose Darkly plugins to Qt applications — 2026-10-15T01:05:00Z

Configured Home Manager's Qt integration with the Darkly Qt 6 style package.
`nix flake check` and the full system build passed. Activated generation
`jdkbfl9yi8yq07cz0j3wg76ihwglf49q-nixos-system-moria-26.05.20261013.a033e66`.
Verified the user's Qt plugin path includes `darkly6.so` and the user manager
exports `QT_STYLE_OVERRIDE=Darkly` and `QT_QPA_PLATFORMTHEME=qt6ct`. The
existing Niri process predates this environment update; a fresh login is
required before Dolphin inherits the updated Qt plugin path. The current
session was left running.

## [COMPLETED] Install Darkly Qt 6 style — 2026-10-15T00:55:00Z

Added Bali10050/Darkly at locked revision
`6fc65177b22983d54aa965ea3617f8c9d658f442`, following the system's pinned
nixpkgs, and installed its Qt 6 style package for qt6ct. `nix flake check` and
the full system build passed. Activated generation
`598p2l7gxl38a3011y3dag74rxsxdyx6-nixos-system-moria-26.05.20261013.a033e66`;
verified `darkly6.so` and Darkly settings/decorations plugins are in the system
profile. The default qt6ct selection was not changed.

## [COMPLETED] Install Breeze Qt style — 2026-10-15T00:50:00Z

Added `kdePackages.breeze` alongside qt6ct. `nix flake check` and dry-build
evaluation passed. Activated generation
`fas5d9kv38rb14gyh7lcr2xsp6hll70p-nixos-system-moria-26.05.20261013.a033e66`;
verified Breeze 6.6.6 is in the system package closure. Choose Breeze as the
widget style in qt6ct if it is not already selected.

## [COMPLETED] Install qt6ct and set Qt platform theme — 2026-10-15T00:45:00Z

Added `qt6Packages.qt6ct` and set `QT_QPA_PLATFORMTHEME=qt6ct` in the
graphical session environment. `nix flake check` and dry-build evaluation
passed. Activated generation
`mmg268y6b1rp00pp1rimv2dh0aygsds6-nixos-system-moria-26.05.20261013.a033e66`;
verified `/run/current-system/sw/bin/qt6ct` is present and `/etc/set-environment`
exports the requested variable. Existing processes keep their old environment;
the variable applies to applications launched in a fresh login session.

## [COMPLETED] Enable UDisks2 for Dolphin devices — 2026-10-15T00:40:00Z

Enabled the NixOS UDisks2 service so Dolphin/Solid can enumerate and manage
removable drives. `nix flake check` and dry-build evaluation passed. Activated
generation `8ysib37piw2ijyq8dcdj0p85rv0zajai-nixos-system-moria-26.05.20261013.a033e66`.
Verified the D-Bus activated `udisks2.service` is running and `udisksctl status`
enumerates the connected internal and external drives. No drive was mounted,
unlocked, or modified.

## [COMPLETED] Install Spotify desktop client — 2026-10-15T00:38:00Z

Add the Nixpkgs Spotify package and allow only the `spotify` unfree package
through this host's existing predicate. `nix flake check` and dry-build
evaluation passed. Activated generation
`q1dwyndjp10w5pmnyfx7wxlnw1pnx12k-nixos-system-moria-26.05.20261013.a033e66`;
verified `/run/current-system/sw/bin/spotify` reports version
`1.2.90.451.gb094aab0`.

## [COMPLETED] Import Fedora Niri shortcuts — 2026-10-15T00:37:00Z

Port the Fedora xremap Caps-layer navigation and window-management shortcuts
to the declarative Niri config. Connect common launcher, settings, lock, browser,
terminal, and Dolphin shortcuts to the installed Noctalia/NixOS applications;
Fedora-only DMS, Vicinae, and custom-helper bindings remain deferred. Niri
validation, `nix flake check`, and the NixOS dry-build evaluation passed.
Activated generation
`xyzh7nz3xvam1qzqjqw90lg7yj1v3m1k-nixos-system-moria-26.05.20261013.a033e66`;
Home Manager deployed the config and its Niri validation passed. Reloaded the
running compositor with `niri msg action load-config-file`; Noctalia's user
service remains active.

## [PENDING] Install xremap with the Fedora configuration — 2026-10-15T02:22:00Z

Copy Fedora's active xremap mapping and three device filters (both IQUNIX
keyboards and the Logitech G502 X LS), grant the `janzon` account the same
`input` group access, and load/configure `uinput` with the Fedora-equivalent
udev rule. Start xremap through a user service bound to
`graphical-session.target` and restart it when the MQ80 USB receiver
(`320f:5055`) reconnects. Validate the configuration, active service, device
access, and no failed system units. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`ldv08n0975kdls9nwi0yvs76q08zknh1-nixos-system-moria-26.05.20261013.a033e66`.
The mapping is byte-for-byte identical to Fedora's active configuration, the
service and udev rules are installed, and there are zero failed system units.
The existing lingering user manager was created before `janzon` joined the
`input` group, so it cannot yet open the selected devices; a reboot is required
to recreate that manager with the declarative group membership, then verify the
active xremap service and mappings.

## [COMPLETED] Tie Noctalia to the Niri graphical session — 2026-10-15T02:20:20Z

The first logout/login after enabling lingering returned to Niri successfully,
confirming the user-manager race is resolved. However, Noctalia was previously
started by Niri as an independent transient scope; it survived logout, retained
the old Wayland connection, and prevented a visible instance in the new
session. Enable Noctalia's NixOS-provided systemd user service and attach it to
`graphical-session.target`, then remove the Niri transient startup command.
Verify that the old process is replaced by the managed service and that it is
active in the current Niri session. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`k0imq0gw4a2vrdhcx14m2v42hxmm7q4p-nixos-system-moria-26.05.20261013.a033e66`.
The previous transient Noctalia process did not exit after logout and was
terminated after confirming its exact stale scope. Verified the replacement
`noctalia.service` is active, the transient scope is absent, and zero system
units are failed.

## [PENDING] Keep the user manager alive across Niri logouts and restore Oo7 unlock — 2026-10-15T02:15:13Z

Previous boots showed a Niri/greetd login race: greetd accepted the next login
while the non-lingering `janzon` systemd user manager was still shutting down
the preceding Niri session, leaving the new graphical session without a live
manager. Fedora's installed configuration has lingering enabled for `janzon`.
Enable `users.users.janzon.linger` declaratively to preserve the user manager
between sessions. Restore Oo7's custom greetd PAM auth/session integration,
with `pam_unix` password capture before `pam_oo7`, so the login password can
unlock Oo7 without restoring GNOME Keyring. Validate the generated PAM stack,
linger state, and system services before attempting a logout/login test.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed. Activated generation
`p2iwml8nfi3bn7yrm4amsb0qsfyn9xh6-nixos-system-moria-26.05.20261013.a033e66`.
Verified `Linger=yes`, successful `linger-users.service` activation, the
generated greetd stack's `pam_unix` → `pam_oo7` → final `pam_unix` order, an
active Oo7 daemon, and zero failed system units. A deliberate logout/login
must still verify that Niri returns normally and Oo7's keyring unlocks.

## [COMPLETED] Disable unsafe Oo7 login integration — 2026-10-15T00:09:10Z

The attempted `pam_oo7` integration for greetd did not unlock Oo7 reliably.
The initial module placement had no `PAM_AUTHTOK`; the follow-up early
`pam_unix` placement was activated in generation
`w3l7w7a5rjgkfnbhjczvzjb92q3n4107-nixos-system-moria-26.05.20261013.a033e66`,
but the next logout/login attempt produced a black screen, a systemd session
allocation failure, and required a reboot. The keyring was not verified
unlocked. Remove the experimental PAM auth/session rules and keep Oo7 as the
desktop Secret Service provider; design a safer Fedora-like unlock path before
attempting another logout test. Removed the experimental PAM module and early
password-capture rules, then passed `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria`. Activated generation
`jpy6m61da6b2l70nal37xmd4yq5zadkw-nixos-system-moria-26.05.20261013.a033e66`.
Verified the generated greetd PAM stack no longer contains `pam_oo7.so`, Oo7's
daemon remains active, and zero system units are failed. Automatic Oo7 unlock
is not configured or claimed to work; a safer design is still pending.

## [COMPLETED] Set Helium as the default browser — 2026-10-15T00:00:00Z

Configure Home Manager MIME associations so Helium handles HTTP, HTTPS, HTML,
XHTML, and XML links/documents. Validation, activation, and live verification
are handled by `helium.desktop`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`jpy6m61da6b2l70nal37xmd4yq5zadkw-nixos-system-moria-26.05.20261013.a033e66`.
Verified the generated `~/.config/mimeapps.list`, Helium desktop entry, and
zero failed system units.

## [COMPLETED] Set timezone to Europe/Warsaw — 2026-10-14T23:55:31Z

Change `time.timeZone` from `Etc/UTC` to `Europe/Warsaw` in the declarative
host configuration. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`7gjcan9k3x5acbcg6g4gq46yfjjg8l15-nixos-system-moria-26.05.20261013.a033e66`.
Verified `Europe/Warsaw` (CEST, UTC+02:00), synchronized NTP, and zero failed
system units.

## [COMPLETED] Install Helium Browser — 2026-10-14T23:55:00Z

Added the pinned Helium Browser flake and enabled its NixOS module. Helium is
installed declaratively and configured to use Oo7 through the
`gnome-libsecret` password store. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`al09v2hn29xvjbfsv1fkf6kzgwkzzmr5-nixos-system-moria-26.05.20261013.a033e66`.
Verified `/run/current-system/sw/bin/helium`, Helium 0.19.2.1, its desktop
entry, and zero failed system units.

## [COMPLETED] Configure Chromium to use Oo7 Secret Service — 2026-10-14T23:49:00Z

Added a declarative wrapper around ungoogled Chromium that passes
`--password-store=gnome-libsecret`, routing Chromium's password storage through
the active Oo7 Secret Service provider. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`zkjqbrxl7nb5fv94gm3nl7lkib13hbrd-nixos-system-moria-26.05.20261013.a033e66`.
Verified the installed Chromium wrapper contains the flag and Oo7 owns
`org.freedesktop.secrets`. Restart Chromium before testing saved credentials.

## [COMPLETED] Set Fish as the default shell — 2026-10-14T23:23:22Z

Enabled `programs.fish` and set `janzon`'s declarative login shell to
`/run/current-system/sw/bin/fish`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated the
configuration as generation
`zkv5b1g1v7min65agn348qkjnjqig5n7q-nixos-system-moria-26.05.20261013.a033e66`.
Verified the account entry, Fish 4.7.1, and zero failed system units.

## [COMPLETED] Set Fish as the system-wide default shell — 2026-10-14T23:24:20Z

Set `users.defaultUserShell = pkgs.fish` so new NixOS user accounts receive
Fish by default, while retaining the explicit `janzon` shell declaration.
Validated with `nix flake check`, `nixos-rebuild dry-build`, and
`nixos-option users.defaultUserShell`; activated generation
`45nbjx7rf8zsnhgpgh5kw8h8m3cxvzkm-nixos-system-moria-26.05.20261013.a033e66`.
No system units are failed.

## [COMPLETED] Install Dolphin file manager — 2026-10-14T23:25:16Z

Added `kdePackages.dolphin` to the system packages. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`1xykvpi97mwn8k0gya7w46xrz61j25z0-nixos-system-moria-26.05.20261013.a033e66`.
Verified `/run/current-system/sw/bin/dolphin`, Dolphin 26.04.3, and zero
failed system units.

## [COMPLETED] Set Polish keyboard layout — 2026-10-14T23:27:29Z

Set the system virtual console keymap to `pl` and the Niri graphical XKB
layout to `pl`. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed; the configuration was activated successfully.
Verified `KEYMAP=pl` in `/etc/vconsole.conf`, successful vconsole setup, and
zero failed system units.

## [COMPLETED] Expose user-local binaries to Fish — 2026-10-14T23:32:05Z

Enabled `environment.localBinInPath` so Fish login sessions include
`/home/janzon/.local/bin`, where the Codex executable is installed. The
configuration passed `nix flake check` and `nixos-rebuild dry-build`, then was
activated successfully. A clean Fish login now resolves Codex and reports
`codex-cli 0.162.1`; zero system units are failed.

## [COMPLETED] Apply Polish Niri keyboard layout — 2026-10-14T23:33:26Z

The active user Niri configuration at `/home/janzon/.config/niri/config.kdl`
was overriding the NixOS fallback configuration. Added `layout "pl"` and
`options "lv3:ralt_switch"` to both the active configuration and the tracked
Niri configuration. Niri validation passed, the compositor was restarted, and
`niri msg keyboard-layouts` now reports `Polish`.

## [COMPLETED] Manage Niri user configuration with Home Manager — 2026-10-14T23:37:33Z

Made the full existing Niri configuration the tracked source at
`home/niri/config.kdl`. Added the pinned Home Manager 26.05 input and deployed
the file declaratively to `~/.config/niri/config.kdl`. The previous unmanaged
file was preserved as `config.kdl.backup`. `nix flake check`, Niri validation,
and `nixos-rebuild dry-build` passed; activation started
`home-manager-janzon.service` successfully.

## [COMPLETED] Complete first-boot Secret Service configuration — 2026-10-14T23:12:14Z

The first boot passed the core desktop, NVIDIA, Wayland, browser, networking,
display, and PipeWire checks. The installed generation did not yet configure
Oo7 as the Secret Service provider: the portal selected the GNOME backend while
GNOME Keyring was disabled, and Oo7 was only installed as a client package.
The repository now adds the pinned Oo7 daemon and portal, D-Bus registration,
the daemon capability wrapper, and the `oo7` portal selection. Activated
generation `dqc84r5k9jijlk2z8y4c1s2wi5wclnpi`. Verified the Oo7 daemon is
running as `janzon`, owns `org.freedesktop.secrets`, and has `cap_ipc_lock`;
verified the generated Niri portal configuration selects `oo7` for the Secret
portal; GNOME Keyring is disabled. Core first-boot checks also pass for Niri,
Noctalia, Ghostty, Wayland Chromium, NVIDIA, display, PipeWire, networking,
and failed system units. A reboot and Fedora firmware-entry check remain.

## [COMPLETED] Final first-boot reboot acceptance — 2026-10-14T23:21:18Z

Checkpoint before reboot: active NixOS generation is
`dqc84r5k9jijlk2z8y4c1s2wi5wclnpi`; Oo7 Secret Service is running; target
filesystem remains UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` with
`nixos-root` and `nixos-home`; ESP remains UUID `38B5-8386` at `/boot`.
Verified Niri on the native 3440x1440 display, NVIDIA RTX 4090, PipeWire,
network connectivity, ungoogled Chromium under Wayland, and no failed system
units. Reboot completed at 23:16 UTC and the system returned to the working
NixOS generation with the expected `nixos-root` and `nixos-home` mounts.
Completed: Fedora was selected from firmware and reported by the user as
booting normally and remaining intact.

## [COMPLETED] Initial parallel installation and pre-reboot bootability gate — 2026-10-14T22:53:30Z

- Important Snapper snapshot verified: `2`, description
  `pre-nixos-parallel-install-20261014`, userdata `important=yes`.
- Target Btrfs verified: filesystem UUID
  `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`, partition UUID
  `e8de64cc-4b7c-44cb-8250-8bcdd3186e28`; new subvolumes only
  `nixos-root` (ID 635) and `nixos-home` (ID 636).
- Target mounts verified with `subvol=nixos-root,compress=zstd:1` and
  `subvol=nixos-home,compress=zstd:1`; existing ESP UUID `38B5-8386` mounted
  at `/boot`; Fedora `root`, `home`, `containers`, and `srv` remain separate.
- ESP backup checksum verified from
  `~/.local/state/nixos-migration/esp-EFI-2026-10-14.tar`:
  `bc10532b864f1611b95daf46aacfe870c3f66518c6e894b3d3b800515c9f6b2a`.
- Installer ISO verified through `/dev/mapper/ventoy`: SHA-256
  `81ec93d823a7ad40f58b14dfcf43de5d794a3aa956564301fa5fcdbe68459f88`.
- Configuration revision installed:
  `13c832ca532efd9ac4421284733a1247ba29efcf`.
- `nixos-install --flake /mnt/etc/nixos#moria` completed successfully and set
  the root password interactively.
- The `janzon` account password was set interactively after installation; no
  password material is recorded here.
- ESP verification passed: `/boot/EFI/systemd/systemd-bootx64.efi`,
  `/boot/EFI/nixos/l94h0skn99v3fqhvzjcr7cvcz202nabd-linux-6.18.56-bzImage.efi`,
  `/boot/EFI/nixos/8da1amvb7rln1mxzhcgsz64xjhvvimf1-initrd-linux-6.18.56-initrd.efi`,
  and `loader/entries/nixos-generation-1.conf` are present.
- UEFI verification passed: separate `Boot0005* NixOS` points to
  `\\EFI\\systemd\\systemd-bootx64.efi`; BootOrder leaves Fedora first and
  NixOS last. Existing Fedora (`EFI/fedora`, `EFI/moria`) and Windows
  (`EFI/Microsoft`) files and UEFI entries remain present.
- The loader entry selects `root=fstab`; installed fstab resolves that to
  filesystem UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` with
  `subvol=nixos-root` and includes `subvol=nixos-home`.
- Bootability gate passed. Mandatory next action: reboot and select the
  explicit `NixOS` UEFI entry for first-boot acceptance; do not change the
  firmware default until acceptance checks pass.

## [COMPLETED] Enable OpenSSH server — 2026-10-15T07:16:11Z

Enabled the declarative OpenSSH server and allowed inbound TCP port 22 through
the NixOS firewall. `nix flake check` (with the required `nix-command flakes`
feature flags) and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed,
then the configuration was activated successfully. Verified `sshd.service` is
enabled and active, listens on IPv4 and IPv6 port 22, and the active IPv4 and
IPv6 firewall chains both accept TCP port 22. The effective SSH policy permits
password authentication for normal users and prohibits root password login;
zero system units are failed.
# [COMPLETED] Migrate HyperHDR from Fedora — 2026-10-15T13:19:46Z

Add HyperHDR v22.0.0.0 from the Fedora source revision to the NixOS
configuration, run it as a user service in the graphical session for PipeWire
capture, and migrate the Fedora HyperHDR state directory. Fedora remains the
source of record and must remain bootable. Pre-change NixOS system profile is
`system-41-link`; no failed system units were reported. Run `nix flake check`,
build the HyperHDR package, and `nixos-rebuild dry-build` before activation.
Verify the service, screen capture portal, retained database, and LED output
after activation. The v22 package build, `nix flake check`, dry build, and
NixOS test activation passed. The Fedora database copy matches its source
checksum. The old PipeWire restoration token was backed up and cleared because
Niri's portal rejected it as an invalid UUID. After the user selected the
monitor, capture exposed a missing EGL runtime library; the HyperHDR wrapper
now includes libglvnd and the active OpenGL driver path. `nixos-rebuild switch`
activated generation `system-43-link`. Verified HyperHDR entered `STREAMING`
with a 3440×1440 PipeWire source using EGL/DMA-BUF acceleration,
`hyperhdr.service` is active with zero restarts, the web UI returns HTTP 200,
and no system units are failed. Fedora remains intact and bootable.

# [COMPLETED] Restore HyperHDR ScreenCast portal routing — 2026-10-15T18:32:47Z

HyperHDR lost access to the PipeWire ScreenCast portal after the graphical
session restarted: the Niri portal configuration did not explicitly route
`org.freedesktop.impl.portal.ScreenCast` to the installed GNOME backend, whose
metadata is otherwise limited to GNOME sessions. Added that declarative route
in `hosts/moria/default.nix`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then
`nixos-rebuild switch --flake /etc/nixos#moria` activated generation
`fn8ljavigzzl4kj4386f536cv5rp8wrd-nixos-system-moria-26.05.20261013.a033e66`.
After restarting the user portal and HyperHDR services, the ScreenCast portal
reported protocol v5 and HyperHDR restored its saved permission, connected to
the 3440x1440 PipeWire stream, entered `STREAMING`, and enabled DMA-BUF GPU
acceleration. `hyperhdr.service` is active with zero restarts and no user units
are failed.

# [COMPLETED] Install Discord — 2026-10-15T20:27:13Z

Added the Discord desktop package to `environment.systemPackages` and allowed
only its unfree package name through the existing restrictive unfree predicate.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed, then `nixos-rebuild switch --flake /etc/nixos#moria` activated
generation `8gw8xqrac3fx1i4s5gf2w6k75n0hxz32`. Verified the `discord`
executable is present in the active system profile, Discord 1.0.159 starts
under Wayland, and no system units are failed.

# [COMPLETED] Add dedicated Niri Overview backdrop — 2026-10-15T20:49:50Z

Added a declarative `swaybg` user service that renders
`wallhaven-vpeq6l.jpg` as a separate background-layer surface on DP-1, plus a
Niri layer rule that places only its `wallpaper` namespace in Niri's Overview
backdrop. The normal Noctalia desktop wallpaper was restored to
`wallhaven-p8r2wj.jpg`. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed; the configuration
was activated as generation `37saps9hdwvfgdwywrhf7l6q8kglnpk0`, and
`niri-overview-wallpaper.service` is active. Niri loaded the deployed
configuration live via `niri msg action load-config-file`; a captured Overview
showed the galaxy image behind the workspace grid while the normal desktop
wallpaper remained unchanged. No user or system units are failed.

# [COMPLETED] Make Overview wallpaper Dolphin action declarative — 2026-10-15

Moved the Dolphin service menu, its wallpaper-setting helper, and the
`niri-overview-wallpaper.service` user override into the NixOS/Home Manager
configuration. The selected Overview wallpaper remains user-managed state at
`~/.config/niri/overview-wallpaper`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then
`nixos-rebuild switch --flake /etc/nixos#moria` activated successfully. The
menu and helper are deployed as executable Home Manager links, the service is
active with zero restarts and exit status 0, and the current wallpaper target
is preserved. The KService cache was rebuilt for Dolphin to discover the new
menu; Niri did not need to be restarted.

# [COMPLETED] Install nomacs image viewer — 2026-10-15

Added nomacs to the declarative system package list, set it as the default
handler for its supported image MIME types, and declaratively selected its
System Theme option while preserving the rest of its user settings.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed, then the system configuration was activated. Verified JPEG and PNG
open with the nomacs desktop entry and its config contains
`themeName312=System Theme`. The already-running nomacs instance was left
untouched; the theme change takes effect after restarting nomacs.

## [COMPLETED] Use Noctalia for rounded display corners — 2026-10-15

Use Noctalia's native screen-corner setting with an 8-pixel radius, matching
the Niri window corner radius. Remove the separate `wayland-rounded-corners`
Home Manager service and flake input. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
configuration was activated. Noctalia accepted `config-reload`; Niri reports
four `noctalia-screen-corner` surfaces on DP-1, `noctalia.service` remains
active, and `rounded-corners.service` is inactive and no longer installed.
No Niri restart was needed.

## [COMPLETED] Bind Caps+V to Vicinae clipboard history — 2026-10-15

Bind the existing Caps+V xremap chord (`Ctrl+Alt+Super+V`) to Vicinae's
clipboard-history deeplink. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build` passed before activation. Reloaded Niri's config
without restarting the compositor and invoked the Vicinae deeplink
successfully; `vicinae.service` remains active.

## [COMPLETED] Bind Caps+Cmd+V to Vicinae snippets — 2026-10-16

Map Caps+Cmd+V to a distinct Niri chord and open Vicinae's `snippets:manage`
command. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation.
Restarted xremap to load the new remap and reloaded Niri without restarting
the compositor. Verified both deployed configs and successfully invoked
`vicinae cmd launch snippets:manage`; xremap and Vicinae are active.

## [COMPLETED] Thin Niri focus ring — 2026-10-16

Reduce the focus-ring width from 4 to 2 logical pixels, preserving its current
colors and 8-pixel corner radius. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build` passed before activation. Reloaded Niri's deployed
configuration successfully without restarting the compositor.

## [COMPLETED] Install ddcutil — 2026-10-16

Add `ddcutil` to the system packages and enable the NixOS I2C module so local
seat users can access `/dev/i2c-*` for monitor DDC/CI control. `nix flake
check` and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed before
activation. Verified `ddcutil` 2.2.7 is installed and, as the regular user,
`ddcutil detect --brief` found the Dell AW3423DWF on DP-1 via `/dev/i2c-4`.

# [COMPLETED] Install Gwenview — 2026-10-15

Added `kdePackages.gwenview` to the declarative system package list without
changing the existing nomacs image associations. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
configuration was activated. Verified the Gwenview executable is available.

# [COMPLETED] Reduce Niri window top and bottom outer gaps — 2026-10-15

Set Niri layout top and bottom struts to `-8`, reducing only the outer
vertical space to eight logical pixels while leaving the global 16-pixel gaps
and Noctalia bar margins unchanged. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. After activation,
the deployed Niri config was loaded live with `niri msg action
load-config-file` and validated successfully; Niri was not restarted.

# [REVERTED] Double Caps+Q quit chord — 2026-10-16

# [PENDING] Restore xremap keyboard devices — 2026-10-16

Caps+Q is restored to its original direct Niri shortcut mapping. During xremap
restart, the kernel disconnected the USB hub branch containing the configured
Telink and RDR input devices. xremap now exits with `No device was selected`,
so the hotkey cannot work until the keyboard/receiver devices reconnect.


The xremap nested sequence stopped producing a usable single Caps+Q action.
Restored the direct Caps+Q to Niri shortcut mapping so the parking action works
again. The double press quit chord is disabled pending a reliable implementation.

# [COMPLETED] Rename and place the background-apps workspace last — 2026-10-16

Rename the named workspace to `background-apps` and place it after ordinary
workspaces, before Niri's required trailing empty workspace. Reorder it at
startup and whenever Caps+Q parks Discord or Spotify. `niri validate`,
`nix flake check`, and `nixos-rebuild dry-build` passed; the change was
activated and loaded live. Verified the workspace follows ordinary workspaces
and that Caps+Q moves Spotify there while leaving focus on the original
workspace. Discord remains there as well.

# [COMPLETED] Add a background-app workspace for Discord — 2026-10-16

Declare a persistent `background-app` Niri workspace. Caps+Q moves a focused
Discord window there while retaining the existing close-window behavior for
other applications. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build` passed; the change was activated with
`nixos-rebuild switch` and loaded live. Invoking the shortcut script moved the
Discord window to the named workspace while leaving focus on the original
workspace. The window was returned to its original workspace after verification.

# [COMPLETED] Round Niri focus ring to 8 px — 2026-10-15

Enabled a global `geometry-corner-radius 8` window rule, which rounds Niri's
focus ring and borders to an 8-pixel radius. Window content is not forcibly
clipped. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. The configuration
was activated and loaded live via Niri IPC; Niri was not restarted.

# [COMPLETED] Clip Niri windows to rounded geometry — 2026-10-15

Enabled `clip-to-geometry true` in the global 8-pixel geometry-corner rule so
window content is clipped to rounded corners, in addition to the rounded
focus ring and border. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. The configuration
was activated and loaded live via Niri IPC without restarting Niri.

# [COMPLETED] Prefer undecorated Niri windows — 2026-10-15

Enabled Niri's top-level `prefer-no-csd` option so applications omit
client-side titlebars and decorations when they support the request. Apps
that explicitly require client-side decorations may retain them, and already
open windows need to be restarted individually. `niri validate`,
`nix flake check`, and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed; the deployed Niri config was activated and loaded live via IPC without
restarting Niri.

## [COMPLETED] Import Jellyfin with Fedora libraries read only — 2026-10-16

Copy the Fedora Jellyfin configuration and cache into NixOS-local writable
state, then run the matching Jellyfin 10.11.11 OCI image. The existing media
directory and all four external volumes are bind-mounted read only. The
container's web port is loopback-only pending the local Caddy service index.
`nix flake check`, `nixos-rebuild dry-build`, and `nixos-rebuild test` ran;
the first test reported a transient startup health-check failure, then the
container reached its ready state. Verified the Podman health check succeeds,
the HTTP endpoint responds with 302, and all data mounts are read only.

## [COMPLETED] Import Syncthing identity from Fedora — 2026-10-16

Copy the existing Syncthing identity and configuration into NixOS-local
writable state and run it with the upstream OCI image. Keep the GUI bound to
localhost for the local Caddy proxy and allow sync protocol TCP/UDP 22000 on
the LAN and Tailscale interfaces. Fedora had no configured sync folders.
`nix flake check` and `nixos-rebuild dry-build` passed before activation.
The service is active and its localhost GUI responds with HTTP 200.

## [COMPLETED] Import qBittorrent with NixOS download storage — 2026-10-16

Copy the Fedora qBittorrent profile into NixOS-local writable state, retaining
the existing torrent metadata and credentials. Mount Fedora torrent and
external volumes read only so existing torrents can seed without modifying
Fedora data. New downloads use `/var/lib/moria/torrents`. The qBittorrent web
port is loopback-only pending the local Caddy index. `nix flake check` and
`nixos-rebuild dry-build` passed before activation. After activation the
service is active, its web endpoint requires authentication, and Podman
reports the Fedora data mounts read only with the NixOS download volume
writable.

## [COMPLETED] Import Nextcloud data and PostgreSQL 17 — 2026-10-16

NixOS-local copies of the Fedora Nextcloud 34.0.2 files, data, and PostgreSQL
17 cluster are ready under `/var/lib/moria/nextcloud`; credentials are stored
outside the repository in `/etc/nextcloud/db.env`. The Fedora source mounts
remain read only. PostgreSQL 17.11 recovered the copied cluster and Nextcloud
reports version 34.0.2 with no database upgrade pending. Its local proxy
responds with the login redirect, the imported library mounts are read only,
and the first background cron pass completed. `nix flake check`, dry-build,
test, and switch passed. Recovery checkpoint remains generation 100 and the
verified snapshot `/btrfs-top/nixos-root-pre-service-import-20261016`.

## [COMPLETED] Add local service links through Caddy — 2026-10-16

Add local reverse proxies and update the Caddy index for Jellyfin, Nextcloud,
Syncthing, and qBittorrent. Links use the current hostname or LAN address;
the imported Fedora HTTPS domains are not used. Open the corresponding ports
on the LAN interface. `nix flake check`, dry-build, test, and switch passed.
Verified the index responds with HTTP 200, Jellyfin and Nextcloud redirect to
their login/setup pages, Syncthing responds with HTTP 200, and qBittorrent
requires authentication.

## [COMPLETED] Enable blur for Vicinae in Umbriel — 2026-10-16

Added an Umbriel layer rule for Vicinae's `vicinae` layer namespace. The active
configuration only applies blur to Noctalia layer surfaces and regular
windows, so it does not match the Vicinae layer surface. Umbriel config
validation, `nix flake check`, and NixOS dry-build passed. Test activation
installed `/nix/store/bslvq6cgc36skdfsfr11d7kvr8kbbkvr-nixos-system-erebor-26.05.20261013.a033e66`.
Umbriel reloaded the layer rules, reported the open `vicinae` surface, and the
user confirmed blur is visible.

## [COMPLETED] Reduce Umbriel blur strength — 2026-10-16

Set `[appearance.blur].radius` to 3, down from Umbriel's default of 5, to
reduce blur strength. Umbriel config validation, `nix flake check`, and
`nixos-rebuild dry-build` passed. `nixos-rebuild test` and `switch` installed
`/nix/store/7cj9dsfgsi9rmh7lc8h7c5f0jhji8xcj-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed config validates, Umbriel reloaded the appearance and scene blur
settings, and both Umbriel and Vicinae are active. The user approved keeping
radius 3 and committing the change.

## [COMPLETED] Repair Umbriel HDR toggle script — 2026-10-16

Fix the generated `umbriel-hdr-toggle` script. Escaped newlines produced an
invalid override, and `jq -e` treated the valid `false` state as an error.
`nix flake check`, dry-build, `nixos-rebuild test`, and `switch` passed. The
deployed script passes `bash -n` and was verified in both directions: HDR
turned off, then on. DP-1 is back in HDR mode (`hdr_active=true`), and the
active NixOS system is
`/nix/store/bl81fynrhj8jhj34ca5pgzi5d7nsnkm0-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Install Konsole — 2026-10-16

Added `kdePackages.konsole` to the system packages. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed; the switch completed
successfully. Verified `/run/current-system/sw/bin/konsole` reports version
26.04.3. Active generation:
`/nix/store/86lb0kmj0740rl5aa1fiz5ax87mmhya1-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Apply Noctalia theme to Discord — 2026-10-17

Enable Vencord in the existing Discord package and initialize its writable
settings with Noctalia Midnight selected. Noctalia's existing community
Discord template owns the generated CSS and follows palette changes.
`nix flake check`, dry-build, test, and switch passed. Noctalia regenerated
all three Vencord theme files with resolved palette colors. Restarted Discord
from the new package; Vencord initialized its settings and retained
`noctalia.theme.css` as the enabled theme. Discord has a live Niri window and
no system units are failed. Active system profile is generation 153:
`/nix/store/bqhjrls9mp0kflpfx2dqgs72ls3c9cdk-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Apply Noctalia theme to Spotify — 2026-10-17

Add Spicetify and a pinned Comfy theme. Launch Spotify from a versioned,
writable copy of its app files so the existing Noctalia Spicetify template
can reapply palette colors without modifying the Nix store. Route the
existing spotify-launcher through the themed package. `nix flake check`,
dry-build, test, and switch passed. Spicetify backup/apply completed;
Noctalia reapplied the template and all generated Comfy colors match
Spotify's patched colors.css. Verified Spotify runs from the writable copy
and has a live Niri window. No system units are failed. Active system
profile is generation 154:
`/nix/store/kvxqdm95lnrw1az8k7svrjhkazq6yr34-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Apply Noctalia theme to Steam — 2026-10-17

Use Millennium's official Nix overlay and pinned Material Theme with the
Matugen color source selected. Repair the Noctalia-created ~/.steam/steam
directory, preserving it as steam.noctalia-bootstrap-backup, so Steam can
link to ~/.local/share/Steam correctly. Starting system profile is generation
155. `nix flake check`, dry-build, build, test, and switch passed.
Added a link from Millennium 3's new theme root to Noctalia's legacy output
path. Steam now starts successfully; Millennium initializes Material Theme
with Color=Matugen and repeatedly reads the generated 4.1 KB matugen.css
according to console-linux.txt. Verified the active theme configuration,
shared CSS path, a live Steam window in Niri, and no failed system units.
Active system profile is generation 156:
`/nix/store/s6cjkbx9fb3bip9znadbxgqhxypbg94n-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Repair Noctalia Next Boot Selector authentication — 2026-10-17

The plugin defaults to pkexec, but a read-only pkexec probe failed with
"No authentication agent found". Configure its privilege_command as
`/run/wrappers/bin/sudo -n`, using the existing sudo policy. A read-only
privileged efibootmgr query succeeded. Validate the flake and dry build,
then activate with `nixos-rebuild test` and reload Noctalia. Generation 156
is the persistent recovery generation. No BootNext is set; boot order and
EFI entries must remain unchanged. Do not reboot or select an entry as a test.

Validation: flake check, dry build, and test activation passed. Noctalia
config reload succeeded and the deployed config has the sudo override.
Read-only sudo efibootmgr succeeds; BootNext remains unset and BootOrder is
unchanged. No system units failed. Test activation is active; persistent
system generation remains 156 (no bootloader activation performed). The
Home Manager config file is deployed and the source change persists for
future rebuilds. No boot selection or reboot was tested. Noctalia logs also
identify the underlying agent registration failure: the passed login session
differs from the caller session. This workaround does not repair that agent.

## [COMPLETED] Add reboot-windows command — 2026-10-17

Add a Home Manager managed ~/.local/bin/reboot-windows command. The user
selected Windows entry 0007 provisionally. Resolve its active Windows loader
by stable shared-ESP partition UUID instead of a fixed firmware entry number.
Set and verify only BootNext before requesting reboot; --dry-run is read-only.
The loader exists at /boot/EFI/Microsoft/Boot/bootmgfw.efi and dry-run resolves
Boot0007. Do not execute the reboot path during validation. Existing BootNext
0001 was already set before this task and is preserved by installation.
Validate flake, dry build, test activation, and deployed dry run. Persistent
recovery generation is 156; do not modify boot order or the ESP.

Validation passed: flake check, dry build, test activation, and installed
reboot-windows --dry-run (Boot0007). Mocked subprocess checks verified the
success sequence and refusal to reboot after failed BootNext writes or
verification. No system units failed. BootNext 0001 and BootOrder are
unchanged; no reboot was performed. Home Manager deployed the executable.
The persistent system generation remains 156; Windows boot success remains
unverified, as requested work was script installation only.

## [COMPLETED] Install Moonlight — 2026-10-18

Add moonlight-qt to the desktop system packages. Validate an isolated source
copy excluding the unrelated pending eza/Fish changes. Existing VFIO
configuration matches the active generation 160. Run flake check and dry-build
before activation; verify the executable and desktop entry afterward.

Flake check, dry-build and full build passed. Moonlight --version reports 6.1.0.
Built system: /nix/store/3ncpxykndiprl5zmxkfi88vznrbysj7h-nixos-system-erebor-26.05.20261013.a033e66.
Pre-activation recovery: generation 160 and read-only root snapshot
/btrfs-top/nixos-root-pre-moonlight-20261018 (Snapper unavailable).
Verify snapshot, test activation, then persist and verify boot entries and mounts.

Verified read-only snapshot 648, UUID 9bfc680d-3b7a-9e4c-9cf0-f85c8bbc68f1.
Test and switch activations succeeded; persistent system generation is 161.
Moonlight 6.1.0 launches graphically and detects the RTX 4090; the desktop
entry is installed. No failed system units. Root and ESP UUIDs unchanged;
UEFI entries/order unchanged, generation 160 retained. No reboot or streaming
session tested. Unrelated pending eza/Fish changes were excluded from activation.
## [COMPLETED] Mark running applications in Right Ctrl chooser — 2026-10-19

The `Ctrl_R+Alt+letter` Vicinae app chooser now shows `●` beside desktop apps
with an open matching window, including its window count; apps without a window
show `○`. The marker is computed from the active Niri or Umbriel window list
immediately before opening the chooser, so it does not rely on process names.
Flake evaluation, Python compilation, diff validation, dry build, and full
build passed. Activated through pkexec as system generation 163; xremap is
active, its deployed rcmd wrapper references the updated source, and
`rcmd --list a` succeeds. There are no failed system units. This terminal is
outside the Niri session, so opening the graphical chooser itself was not
automated; verify its visual markers with Right Ctrl+Alt+letter in Niri.

## [COMPLETED] Order running applications first in Right Ctrl chooser — 2026-10-19

Sort the `Ctrl_R+Alt+letter` Vicinae chooser by active window state before
name, keeping the existing `●` marker and window count. Flake check, Python
compilation, and dry-build passed. Activated through pkexec as generation 164;
the deployed rcmd source contains the state-first ordering and no system units
failed. Verify the graphical order in the active Niri session.

## [COMPLETED] Bypass xremap in Moonlight — 2026-10-19

Exclude the observed `com.moonlight_stream.Moonlight` app ID and `moonlight`
from all general modmap/keymap rules, including CapsLock and Right Ctrl.
Application-only terminal rules already exclude Moonlight. Forward CapsLock
press/repeat/release directly in Moonlight because virtual modifiers otherwise
remain swallowed even without a matching keymap.

Flake check, NixOS dry-build, and Home Manager build passed. Activated only
Home Manager to avoid applying unrelated pending PAM changes; the deployed
config matches the source and xremap was restarted successfully. An isolated
virtual keyboard with its output grabbed away from applications verified exact
Ctrl+A, Right Ctrl+A, Super+A, CapsLock, and held CapsLock+A event passthrough
while the actual Moonlight window was focused. Ghostty still remaps Super+A
to Ctrl+A. Original window focus restored. Streaming-host behavior was not
exercised because the test events were captured locally.

System generation remains 172; root and ESP UUIDs are unchanged. No failed
system or user units. No system/boot activation or reboot was needed.


## [COMPLETED] Enable Intel UHD 770 hardware video decoding — 2026-10-19

Moonlight reports no hardware video decoder. The live graphics driver directory
lacks iHD_drv_video.so and FFmpeg VA-API device initialization fails on
/dev/dri/renderD128. Add intel-media-driver to hardware.graphics.extraPackages.
Validate an isolated source copy excluding the unrelated pending sudo/YubiKey
policy, then test-activate and verify VA-API and an actual hardware decode.
Pre-change persistent generation: 172. Root/ESP UUIDs match the recorded system;
no failed system units. No boot, firmware, VFIO or display-setting changes.

Flake check, dry-build and full build passed. Test activation succeeded using
Polkit. /run/opengl-driver/lib/dri/iHD_drv_video.so is deployed. FFmpeg using
the normal system driver path decoded all 60 H.264 test frames via VA-API
with zero errors. No failed system units. The active system is
/nix/store/mnma7hiid1rr86b034vx58d7xf65b5h2-nixos-system-erebor-26.05.20261013.a033e66.
Persistent boot generation remains 172; no bootloader, EFI or VFIO changes.
The driver is active for this boot and declared for future system rebuilds;
perform a normal switch before rebooting to retain it in the boot generation.
Moonlight must restart to repeat decoder detection; streaming and compositor
frame delivery after this driver fix have not been verified.

## [PENDING] Bridge Windows VM onto the wired LAN — 2026-10-19

User authorized direct LAN networking. Define NetworkManager br0 and its
enp4s0 port, move existing LAN host firewall allowances to br0, and use br0
for newly created VMs. Existing windows11 interface will be migrated live
and persistently, retaining its MAC. Pre-change XML: /tmp/windows11-before-lan-bridge.xml.
Flake check, dry-build, and full build passed using an isolated source tree
that excludes the unrelated pending modules/mac-approval.nix changes.
Built system: /nix/store/4yqv3l0h050gjs4grclz4j22d6d378ya-nixos-system-erebor-26.05.20261013.a033e66.
Recovery: test-activated system was /nix/store/mnma7hiid1rr86b034vx58d7xf65b5h2-nixos-system-erebor-26.05.20261013.a033e66; persistent generation 172
remains available. Before activation, create and verify the read-only root
snapshot /btrfs-top/nixos-root-pre-lan-bridge-20261019.
Read-only root snapshot 651 verified, UUID f3d8aea9-7a46-2447-a944-6dabf8f4f304.
Test activation succeeded. Host retains 192.168.1.106 on br0, its default
route and DNS work, and router ping has zero packet loss after DHCP settles.
The running and persistent windows11 interfaces now use br0 and the router
assigned 192.168.1.120. Sunshine TCP ports 47984, 47989, 47990 and 48010
are reachable; /serverinfo returns status 200 and hostname gamestation.
The host HTTP service still returns 200. Windows does not answer ping;
no guest firewall changes were needed for Sunshine. Persistent pre-migration
XML backup: /home/janzon/.local/state/windows-vm/pre-lan-bridge-20261019/windows11.xml.
Root/ESP UUIDs verified; no failed units.
Next: authenticate the pending persistent switch, then verify generation,
boot entries, mounts, and services. No reboot planned. Playback from another
physical LAN device has not been exercised.
