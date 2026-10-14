# NixOS `moria` migration instructions

Read `INSTALL_PLAN.md` completely before changing any system state. This is a
parallel NixOS installation beside a working Fedora and Windows system.

## Scope and storage safety

- Identify storage only by these stable identifiers, never by a transient
  `/dev/sdX` or `/dev/nvme...` name:
  - target Btrfs filesystem UUID: `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`
  - target Btrfs partition UUID: `e8de64cc-4b7c-44cb-8250-8bcdd3186e28`
  - existing ESP filesystem UUID: `38B5-8386`
  - existing ESP partition UUID: `01efe05e-d3eb-4ebd-a310-6fb83809c645`
  - Ventoy filesystem UUID: `2AEC-3324`
  - Ventoy partition UUID: `66998bcd-01`
- Create only the `nixos-root` and `nixos-home` Btrfs subvolumes.
- Never run partitioning, formatting, signature-wiping, or recursive deletion
  commands for this project. Do not mount Fedora's `root` or `home` as the
  NixOS root/home target.
- Stop and ask the user if any UUID, free-space check, partition identity, or
  expected subvolume is different from the plan.

## Required safeguards

- Immediately before creating subvolumes or modifying the ESP, create and
  verify an important manual Snapper snapshot. Back up the ESP separately;
  Snapper does not include it.
- Preserve all Fedora and Windows UEFI files and boot entries. Add a separate
  NixOS boot entry only; do not make NixOS the global default until both
  systems have passed their boot tests.
- Before first NixOS boot, retain the Fedora host's required records under
  `/home/janzon/`. After installation, record NixOS changes and the verified
  snapshot number in this repository's `/etc/nixos/SYSTEM_CHANGELOG.md`, and
  update `/etc/nixos/SYSTEM_CONTEXT.md` if verified NixOS state changes
  materially. Do not duplicate declarative packages, services, options, or
  topology that can be derived from the Nix flake and modules. Context is only
  for non-declarative runtime facts, intentional exceptions, external/manual
  recovery information, and verified operational pitfalls.
- Keep `SYSTEM_CONTEXT.md` concise and current. Include only important facts
  relevant to ongoing operation; remove entries as soon as they are obsolete,
  superseded, or no longer apply. Do not use it as a historical record;
  completed change history belongs in `SYSTEM_CHANGELOG.md`.
- Treat every reboot as a handoff boundary. Before rebooting after a material
  installation/configuration action, write and read back a checkpoint in the
  target system's changelog with the exact completed state, snapshot number,
  validation performed, and mandatory next action. Add a temporary context
  exception only when the unvalidated state is operationally important; remove
  it once it no longer applies.
- Use `SYSTEM_CHANGELOG.md` for both completed changes and pending material
  operations. Prefix pending entries with **[PENDING]**; when completed, edit
  that same entry to **[COMPLETED]** and add the verification result. Keep
  `INSTALLATION_LOG.md` as the chronological, concise installation record.
- A reboot is prohibited unless the bootability gate in `INSTALL_PLAN.md` has
  passed and is recorded in both the changelog checkpoint and installation log.

## Initial NixOS scope

- Include only NVIDIA, Niri, Noctalia, Ghostty, the Wayland/portal/audio
  essentials, ungoogled Chromium as the sole initial browser, and Oo7 as the
  sole desktop Secret Service provider. Do not add KWallet or GNOME Keyring in
  the first generation.
- Do not migrate services, personal dotfiles, containers, HyperHDR, LedFx,
  gaming, secrets, or user profiles in the first generation.
- Use the official Noctalia NixOS module and Niri's `niri-session`; launch
  Noctalia from Niri. Avoid an ad-hoc competing systemd user service.

## Secrets and source control

- Keep secrets, passwords, Wi-Fi credentials, browser profiles, controller
  backups, tokens, and private keys out of this project and the Nix store.
- Keep configuration in this project as a Git repository, with a committed
  lock file once the initial system has been validated.
