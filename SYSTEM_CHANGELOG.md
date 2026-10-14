# NixOS system change log for `moria`

Record completed NixOS configuration changes and material pending operations
here. Prefix active work **[PENDING]**; change that entry to **[COMPLETED]**,
**[BLOCKED]**, or **[CANCELLED]** with its final result. Do not record
secrets, routine read-only inspections, or one-off command failures.

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
