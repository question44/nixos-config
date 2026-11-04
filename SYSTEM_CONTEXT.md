# System context for NixOS `erebor` (flake target `erebor`)

Verify live state before acting; this file is not a system inventory.

This document becomes the NixOS-side operational memory after the parallel
installation. Verify live state before acting and do not record passwords,
tokens, private keys, browser profiles, Wi-Fi credentials, or other secrets.
Keep it concise: retain only important information relevant now, and remove an
entry when it becomes obsolete, superseded, or no longer applies. Historical
changes belong in [SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md), not here.
Unfinished work and verification checks belong in
[SYSTEM_TODO.md](SYSTEM_TODO.md); do not duplicate task status here.

## What belongs here

- Non-declarative runtime facts verified on this host.
- Intentional exceptions or manual state that cannot be expressed in the Nix
  flake/modules.
- External recovery locations, hardware quirks, and safe validation steps.
- Reusable, verified operational pitfalls and their prevention/recovery.

## What does not belong here

- Packages, service definitions, mount topology, bootloader settings, desktop
  configuration, or any other state that can be derived from the flake and
  modules. The repository is authoritative for those.
- Secrets or one-off command history.

## Reusable operational pitfalls

- With unpublished local dashboard submodule commits, build the full local tree
  using `--flake path:/etc/nixos#erebor`; the Git flake URL with `submodules=1`
  can try to fetch the submodule commit from its remote and fail before it is
  published. This does not change the pinned dependency versions.

- NanoKVM's manual Tapo reader is `/opt/tapo-query/tapo-query`, linked into
  `/usr/bin`. Its root-only runtime credentials are under `/etc/tapo-query`,
  separate from the desktop Oo7 keyring. Rebuild/redeploy from
  `/home/janzon/Projects/tapo-query/deploy-nanokvm.py` in an unlocked desktop
  session after NanoKVM firmware recovery or credential rotation. The Nix
  cross-build must use static linkage; a Nix dynamic loader is unavailable on
  NanoKVM. See the dated NanoKVM Tapo entry in `SYSTEM_CHANGELOG.md`.
  The dashboard helper exposes the reader through owner-authenticated `/outlet`
  when `outletEnabled` is true in `/opt/erebor-wake/config.json`. Restore both
  helper and private config after firmware recovery; frontend `outletUrl` alone
  does not install or enable the NanoKVM endpoint.

- NanoKVM `kvm-37ff` hosts the dashboard wake helper outside `/kvmapp`, in
  `/opt/erebor-wake`, started by `/etc/init.d/S99erebor-wake`. This remote
  installation is manual state, not activated by the NixOS flake. Its private
  Tailscale Serve config persists independently. Redeploy from the dashboard
  submodule and host config after firmware recovery if necessary; see SYS-039
  and the submodule README. Power LED signals describe motherboard state,
  not OS responsiveness; hardware acceptance is tracked in SYS-040.
  OS probes use tailscaled’s local Unix socket: launching the Go CLI per probe
  caused load and timeouts on this device; retain the socket-based implementation.

- For deployments using the private dashboard submodule, run
  `nixos-rebuild test/switch --sudo --flake /etc/nixos#erebor` as janzon so Nix
  evaluates with the user's Git/SSH access and sudo handles activation. A full
  root invocation tried to fetch GitHub without trusted-host/user SSH state;
  no root SSH trust changes were made. Verified during SYS-036 deployment.

- The private dashboard submodule needs GitHub SSH access when Nix fetches a
  clean Git source. Evaluate/build as the SSH-authenticated user; for deployment,
  `nixos-rebuild test --sudo --flake /etc/nixos#erebor` reserves sudo for activation.
  The installed rebuild command supports `--sudo`; do not copy SSH keys to root
  or into the Nix store. See SYS-037 for the tested clone/build evidence.

- GRUB migration retains firmware **Linux Boot Manager** (0004), loading
  `/EFI/systemd/systemd-bootx64.efi`, and its existing generation menu as a
  recovery path. GRUB also offers a systemd-boot recovery chainload. Verified
  preserved at installation on 2026-10-23; see SYS-029 for first-boot acceptance.

- Windows VM disk now resides on Crucial UUID `604F-A363` at
  `/srv/external/crucial/windows11.qcow2`. The live local image was removed;
  NixOS recovery snapshots retain its blocks. Older domain XML must have its
  source path updated before reuse, or be paired with a restored original
  disk/NVRAM/TPM. See [Windows VM recovery](WINDOWS_VM.md#disk-location-and-recovery).

- Interactive sudo supports YubiKey authentication through a PTY; noninteractive
  sudo can report that a password is required even when a YubiKey is available.
- A newly added kernel module is not found by default modprobe after a NixOS
  test activation because it searches `/run/booted-system/kernel-modules`.
  For a module built against the running kernel, load it with
  `modprobe --dirname /run/current-system/kernel-modules <module>`.
- NixOS libvirt copies qemu.conf through libvirtd-config.service at daemon
  startup. After changing its device ACL, restart libvirtd to load it;
  test activation alone leaves an already-running daemon on its old config.
- Windows Looking Glass IDD needs **Force indirect copy** on this UHD 770:
  direct transport produced missing strips/blocks even with full-frame copies.
  The guest registry workaround and recovery locations are in WINDOWS_VM.md.
