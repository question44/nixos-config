# System context for NixOS `erebor` (flake target `erebor`)

Verify live state before acting; this file is not a system inventory.

This document becomes the NixOS-side operational memory after the parallel
installation. Verify live state before acting and do not record passwords,
tokens, private keys, browser profiles, Wi-Fi credentials, or other secrets.
Keep it concise: retain only important information relevant now, and remove an
entry when it becomes obsolete, superseded, or no longer applies. Historical
changes belong in [SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md), not here.
Unfinished work and verification checks belong in
[tasks/](tasks/README.md); do not duplicate task status here.

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

## Recovery locations

- Offline copy of janzon's sops age key (`~/.config/sops/age/keys.txt`, a
  `.sops.yaml` recipient): `sops-age-janzon-keys.txt` (root, 0400) on the
  ext4 partition labelled `LUKS_KEY` of the Ventoy USB flash drive, next to
  `moria-root-luks.key`. Copied and checksum-verified 2026-11-08. Without it
  or erebor's SSH host key, `secrets/*.yaml` cannot be decrypted.

- The live `sequoia:` wallpaper (modules/sequoia-wallpaper.nix) loads
  `~/.local/share/sequoia/sequoia.scene`, which is user data outside the flake
  (Apple's scene data, kept out of git and the store). Regenerate it from the
  reverse-engineering checkout with
  `python3 -I ~/src/sequoia-re/tools/pack.py ~/src/sequoia-re/build ~/.local/share/sequoia/sequoia.scene`
  (inputs come from the MacBook's WallpaperSequoiaExtension; see
  `~/src/sequoia-re/NOTES.md`). Without it Noctalia logs `sequoia: cannot load
  scene` and the wallpaper shows only the fill colour. The patch source is the
  `sequoia-live` branch of `~/src/noctalia-sequoia`.

## Reusable operational pitfalls

- `xremap.service` reads `~/.config/xremap/config.yml` only at startup and
  activation does not restart it. After any xremap config change, run
  `systemctl --user restart xremap` and verify the remap.

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
  Restart tailscaled over LAN SSH (`root@192.168.1.122`), not over Tailscale.
  `S98tailscaled stop` does not wait for exit: confirm the old PID is gone before
  start (SIGKILL if needed), or both daemons share state and exhaust ~158 MiB RAM.

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
  disk/NVRAM/TPM. See [Windows VM recovery](docs/windows-vm.md#disk-location-and-recovery).

- Interactive sudo supports YubiKey authentication through a PTY; noninteractive
  sudo can report that a password is required even when a YubiKey is available.
  Two YubiKeys are enrolled in `/etc/security/yubico/u2f_keys` (2026-11-06).
- Mac approval comes from the MacBook (`Jans-MacBook-Pro`, user janzon, LAN
  192.168.1.97): launchd agent `~/Library/LaunchAgents/com.janzon.erebor-ssh.plist`
  (KeepAlive, 15 s throttle) runs `ssh -A erebor`, which symlinks the forwarded
  Secretive agent to `/run/mac-approval/janzon/agent.sock`. The Mac's
  `~/.ssh/config` uses erebor's Tailscale IP when the Mac is on Tailscale, else
  192.168.1.106 (`HostKeyAlias 192.168.1.106`). Homebrew sleepwatcher runs
  `~/.sleep` (launchctl bootout of the agent) and `~/.wakeup` (bootstrap).
  macOS answers TCP keepalives while asleep, so sshd's ClientAlive Match is the
  backstop if the hooks don't run.
- The long-running Vicinae daemon does not pick up applications added by a
  `nixos-rebuild switch`; run `systemctl --user restart vicinae` to rescan
  (verified 2026-11-04 with Google Chrome).
- Apps started from Noctalia's launcher, dock or bar run in their own
  `app-<id>@<uuid>.service` because `[shell] launch_apps_as_systemd_services`
  is set (verified 2026-11-10). Without that option they run inside
  `noctalia.service`'s cgroup, so a Noctalia stop or restart (an activation
  that changes its package) kills them. Chromium-based browsers move only
  their main PID to their own scope, so they lose their GPU process and zygotes and abort with "GPU process
  isn't usable. Goodbye." (verified 2026-11-09, [SYS-096](tasks/SYS-096.md)).
  Check with `systemctl --user status noctalia.service` before an activation.
- A newly added kernel module is not found by default modprobe after a NixOS
  test activation because it searches `/run/booted-system/kernel-modules`.
  For a module built against the running kernel, load it with
  `modprobe --dirname /run/current-system/kernel-modules <module>`.
- NixOS libvirt copies qemu.conf through libvirtd-config.service at daemon
  startup. After changing its device ACL, restart libvirtd to load it;
  test activation alone leaves an already-running daemon on its old config.
- Windows Looking Glass IDD needs **Force indirect copy** on this UHD 770:
  direct transport produced missing strips/blocks even with full-frame copies.
  The guest registry workaround and recovery locations are in [docs/windows-vm.md](docs/windows-vm.md).
