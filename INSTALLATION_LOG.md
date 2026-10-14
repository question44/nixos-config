# NixOS installation log for `moria`

This is the concise chronological record for the parallel NixOS installation.
Record material installation actions before every reboot: timestamp, action,
result, validation, status (`[PENDING]` or `[COMPLETED]`), and the required
next action. Do not include secrets or verbose command output.

## 2026-10-14T22:45:55Z — [COMPLETED] Initial installation and pre-reboot gate

Verified the required installer ISO SHA-256
`81ec93d823a7ad40f58b14dfcf43de5d794a3aa956564301fa5fcdbe68459f88` through
the mapped Ventoy device. Verified target filesystem and partition UUIDs,
approximately 198 GiB estimated free space, Fedora subvolumes, and the
existing ESP. Verified Snapper snapshot 2 and the ESP archive checksum
`bc10532b864f1611b95daf46aacfe870c3f66518c6e894b3d3b800515c9f6b2a`.

Created only `nixos-root` (ID 635) and `nixos-home` (ID 636), mounted them at
`/mnt` and `/mnt/home` with `compress=zstd:1`, and mounted ESP UUID `38B5-8386`
at `/mnt/boot`. Generated hardware configuration and validated the installed
configuration lineage with `nix flake check`.

`nixos-install --flake /mnt/etc/nixos#moria` completed successfully. The
installed configuration revision is
`13c832ca532efd9ac4421284733a1247ba29efcf`. The ESP contains systemd-boot,
the NixOS kernel/initrd, and `loader/entries/nixos-generation-1.conf`; its
loader entry uses `root=fstab`, and the installed fstab selects
`subvol=nixos-root` and `subvol=nixos-home` on the target filesystem UUID.

Created and verified separate UEFI entry `Boot0005* NixOS` pointing to
`\\EFI\\systemd\\systemd-bootx64.efi`. Fedora and Windows UEFI entries and
their `EFI/fedora`, `EFI/moria`, and `EFI/Microsoft` paths remain present.
BootOrder leaves Fedora first and NixOS last. The bootability gate passed.

Required next action: reboot and explicitly select `NixOS` from firmware for
first-boot acceptance. Do not change the firmware default until acceptance
checks pass.
