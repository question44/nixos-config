# NixOS system change log for `moria`

Record completed NixOS configuration changes and material pending operations
here. Prefix active work **[PENDING]**; change that entry to **[COMPLETED]**,
**[BLOCKED]**, or **[CANCELLED]** with its final result. Do not record
secrets, routine read-only inspections, or one-off command failures.

## [PENDING] Initial parallel installation — 2026-10-14T22:45:55Z

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
- Configuration revision staged for installation:
  `b7396669dcb51df423c31b9c2b38168e6336e8be`.
- Pending next action: run `nixos-install --flake /mnt/etc/nixos#moria`,
  verify the separate NixOS UEFI entry and preserved Fedora/Windows entries,
  then record the complete bootability gate before rebooting.
