# NixOS parallel installation plan for `moria`

## Objective

Install a minimal, bootable NixOS 26.05 system beside Fedora on the existing
Btrfs filesystem. The first NixOS generation must provide:

- the proprietary NVIDIA driver for the RTX 4090;
- Niri, launched through `niri-session`;
- Noctalia, launched from Niri;
- Ghostty as the installed terminal, launched by the Niri terminal shortcut;
- ungoogled Chromium as the sole initial, Wayland-capable browser.

This is a parallel install. It must not modify Fedora's root/home subvolumes,
Windows partitions, container data, or existing Fedora UEFI files.

## Verified starting state (2026-10-14)

- Target Btrfs filesystem UUID: `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`
  (partition UUID `e8de64cc-4b7c-44cb-8250-8bcdd3186e28`, label
  `fedora-unencrypted`).
- Fedora subvolumes to preserve: `root`, `home`, `containers`, and `srv`.
- Available Btrfs space: about 121 GiB. Do not proceed below 80 GiB free.
- Existing ESP filesystem UUID: `38B5-8386` (partition UUID
  `01efe05e-d3eb-4ebd-a310-6fb83809c645`), mounted by Fedora at `/boot/efi`,
  with about 5.9 GiB free. Secure Boot is disabled.
- GPU: NVIDIA AD102 / GeForce RTX 4090 (`10de:2684`).
- Installer medium: the existing Ventoy filesystem UUID `2AEC-3324`
  (partition UUID `66998bcd-01`); never repartition or format it. Its NixOS
  ISO must be verified before booting.

## Non-negotiable safety rules

1. Work only with Btrfs filesystem UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`
   and its two new subvolumes:
   `nixos-root` and `nixos-home`.
2. Never run `mkfs`, `wipefs`, `parted`, or `fdisk` on any disk or partition.
3. Never mount Fedora's `root` or `home` as the NixOS root or home directory.
4. Back up the ESP before adding the NixOS bootloader. Snapper does not cover
   the ESP.
5. Create and verify an important Snapper snapshot immediately before Btrfs
   subvolume or ESP changes. Record its number in `SYSTEM_CHANGELOG.md` after
   the install succeeds.
6. Keep the new NixOS boot entry separate from Fedora's custom UEFI entries.
   Fedora and Windows must remain available from firmware boot selection.
7. Do not put passwords, Wi-Fi secrets, browser profiles, tokens, or private
   keys in this repository or Nix store.

## Phase 0 — prepare and verify the installer

1. Check that the graphical installer ISO on Ventoy has exactly this SHA-256:

   ```text
   81ec93d823a7ad40f58b14dfcf43de5d794a3aa956564301fa5fcdbe68459f88
   ```

   This is for
   `nixos-graphical-26.05.11829.a033e66ab94a-x86_64-linux.iso`.

2. If its byte count or checksum differs, remove only that ISO and download it
   again from the matching official `releases.nixos.org` release. A partial or
   concatenated ISO must never be booted.
3. Ensure Fedora can still see approximately 121 GiB free in the target Btrfs
   filesystem and that its UUID still matches the target UUID above.
4. Keep the Ventoy drive connected, reboot, select the verified **graphical**
   NixOS ISO in Ventoy, and boot the installer. If NixOS does not boot, select
   Fedora from firmware boot selection; do not alter disk layout to troubleshoot
   it.

## Phase 1 — installer-console preflight

In the NixOS installer, confirm all of the following before any write:

```bash
lsblk -f
btrfs filesystem show
```

Stop immediately unless:

- the target Btrfs filesystem UUID matches the UUID above;
- the ESP filesystem UUID is `38B5-8386` and its partition UUID is
  `01efe05e-d3eb-4ebd-a310-6fb83809c645`;
- the Fedora `root` and `home` subvolumes are visible at Btrfs top level;
- there is at least 80 GiB estimated free space.

Mount the Btrfs top level only, never a Fedora subvolume, at a temporary
location such as `/mnt/btrfs-top`. Create only:

```text
nixos-root
nixos-home
```

Mount `nixos-root` at `/mnt`, `nixos-home` at `/mnt/home`, and the existing
ESP at `/mnt/boot`. Use explicit `subvol=` and `compress=zstd:1` mount options.
Do not mount Fedora's separate `/boot` partition (partition UUID
`156e231a-e6d5-4494-8744-998436524a21`) in the NixOS target.

## Phase 2 — recovery measures immediately before changes

From Fedora before rebooting to the installer, or from a verified Fedora
rescue boot if necessary:

1. Create an important manual Snapper snapshot with a description such as
   `pre-nixos-parallel-install` and verify it appears in `sudo snapper list`.
2. Create a dated backup of the ESP's `EFI` directory under
   `~/.local/state/nixos-migration/`, preserving its contents and recording a
   checksum. This is an ESP-file recovery copy, not a replacement for a
   hardware backup.
3. Capture `efibootmgr -v`, Btrfs subvolume list, Btrfs filesystem usage, and
   the EFI backup checksum in the project’s install record. Do not record
   secrets.

## Phase 3 — Nix configuration

Create a Git repository at this project path. Use a flake pinned to the NixOS
26.05 stable branch plus the official Noctalia flake input. Keep modules
small:

```text
AGENTS.md
SYSTEM_CONTEXT.md
SYSTEM_CHANGELOG.md
INSTALLATION_LOG.md
flake.nix
hosts/moria/default.nix
hosts/moria/hardware-configuration.nix  # generated by the installer
modules/desktop.nix
modules/nvidia.nix
home/niri/config.kdl
```

Before `nixos-install`, copy this complete repository (including the three
operational documents) to `/mnt/etc/nixos`. The installed system's canonical
agent instructions and NixOS records are therefore `/etc/nixos/AGENTS.md`,
`/etc/nixos/SYSTEM_CONTEXT.md`, and `/etc/nixos/SYSTEM_CHANGELOG.md`.
Do not depend on Fedora's separate home subvolume to access them.

The initial configuration must include:

- `programs.niri.enable = true`;
- a `greetd` login session that runs Niri's `niri-session` for `janzon`;
- `systemd.user.services.niri.enableDefaultPath = false`;
- PipeWire/WirePlumber, NetworkManager, polkit, DBus, and Oo7 as the sole
  Secret Service; do not install KWallet or GNOME Keyring;
- xdg-desktop-portal with the Niri module's automatic GNOME screencast backend
  and GTK fallback; set `programs.niri.useNautilus = false` so no Nautilus
  file chooser is installed, and route the Secret portal to Oo7;
- Xwayland Satellite;
- NVIDIA proprietary drivers, modesetting, OpenGL/Vulkan support, and
  `allowUnfree` limited to the required unfree packages;
- Noctalia through its official NixOS module. Enable its recommended services,
  but launch Noctalia from Niri (`spawn-at-startup "noctalia"`) rather than
  creating a competing ad-hoc user service;
- a minimal Niri configuration with a terminal, application launcher, exit
  shortcut, and Noctalia startup. Do not import the existing large Fedora Niri
  configuration in the first generation;
- Ghostty (`pkgs.ghostty`) installed system-wide, with the Niri terminal
  shortcut configured to run `spawn "ghostty"`;
- `pkgs.ungoogled-chromium` as the only initial browser. Do not add Firefox,
  Zen, Helium, or another browser in the first generation.

Do not enable Steam, HyperHDR, LedFx, Podman, Caddy, Tailscale, Samba, Snapper,
or any custom Fedora service in the first generation.

## Phase 4 — install and bootloader

1. Generate `hardware-configuration.nix` only after the target subvolumes and
   ESP are mounted in their final locations.
2. Configure systemd-boot to use the existing ESP and permit EFI variable
   writes. It must create a distinct **NixOS** UEFI entry; it must not delete,
   rename, or replace any `EFI/moria`, `EFI/fedora`, or `EFI/Microsoft` paths.
3. Run `nixos-install --flake /mnt/etc/nixos#moria`.
4. Set the root password interactively when prompted. Do not place it in the
   configuration.
5. **Before rebooting**, update and read back
   `/mnt/etc/nixos/SYSTEM_CHANGELOG.md`. Record the successful root install,
   Snapper snapshot number, Btrfs filesystem/subvolume identifiers, exact
   configuration revision, what was verified, and the mandatory next action.
   If bootloader installation or its NVRAM entry is not yet verified, state
   that plainly; do not claim the system is accepted or bootable.
6. Add a temporary entry to `/mnt/etc/nixos/SYSTEM_CONTEXT.md` only if an
   important unvalidated condition remains (for example, an initial boot or a
   separate UEFI entry is still pending). This entry must be removed once the
   condition has been resolved.
7. Append the same facts to `/mnt/etc/nixos/INSTALLATION_LOG.md`, including
   timestamps, the pending/completed state, and the next required action.
8. Pass this **bootability gate** before any reboot:
   - `nixos-install` completed successfully;
   - the ESP is mounted at `/mnt/boot` and contains the new NixOS bootloader
     file(s);
   - `efibootmgr -v` contains a separate NixOS entry pointing to those files;
   - the pre-existing Fedora and Windows entries/files remain present;
   - the entry's root parameters/selectable generation reference the
     `nixos-root` subvolume; and
   - all five facts are written to the pending changelog entry and installation
     log.
   If any check fails, **do not reboot**: repair the bootloader while still in
   the installer and retain the operation as `[PENDING]`.
9. Only after the gate passes, mark the bootloader operation `[COMPLETED]` in
   the changelog, append the final pre-reboot log result, and reboot. Select
   NixOS explicitly from the firmware boot menu for first boot;
   do not change the global boot order until NixOS is proven usable.

## Phase 5 — first-boot acceptance

Pass all of these checks before adding more services:

1. NixOS boots to the Niri/Niri login path without requiring Fedora files.
2. NVIDIA is active (`nvidia-smi`) and the monitor runs at its intended native
   resolution and high refresh rate.
3. Noctalia is visible and functional: panel, launcher, notifications, and
   wallpaper service. Confirm only one notification daemon is active.
4. The chosen browser starts under Wayland and can reach the Internet.
5. Audio output works through PipeWire.
6. Ghostty opens from the Niri terminal shortcut and provides a working shell.
7. Reboot once and confirm the system remains bootable.
8. Select Fedora from firmware boot selection and confirm it remains intact.
9. From NixOS, run `nixos-rebuild test --flake /etc/nixos#moria` after a
   harmless change, then reboot to confirm this temporary generation did not
   become the default.

## Phase 6 — document and only then expand

After all acceptance checks pass:

1. Append a concise NixOS installation entry to
   `/etc/nixos/SYSTEM_CHANGELOG.md` with the verified snapshot number,
   subvolume names, EFI strategy, and validations.
2. Update `/etc/nixos/SYSTEM_CONTEXT.md` only with non-declarative facts or
   recovery/pitfall knowledge that cannot be derived from the flake and
   modules; omit secrets and account tokens. Keep it concise and remove
   obsolete or superseded information rather than retaining history, including
   the temporary pre-boot exception from Phase 4.
3. Commit the sanitized Nix configuration and its lock file to this project.
4. Add later workloads one at a time: first existing Niri keybindings and
   xremap, then HyperHDR/WLED, then gaming/apps, then network/container
   services. Each addition gets a build, switch/test, and live verification.

## Rollback

- If the installer has not created subvolumes: reboot to Fedora; no disk state
  should have changed.
- If NixOS fails to boot: choose Fedora or Windows in the UEFI boot menu. Do
  not delete subvolumes until Fedora and the ESP backup have been checked.
- If an installed NixOS generation fails: select an earlier NixOS generation
  from its boot menu or run `nixos-rebuild switch --rollback` from a working
  NixOS session.
- If Fedora boot files were unexpectedly changed: boot Fedora through its
  existing UEFI entry and restore only the affected files from the dated ESP
  backup after comparison.
