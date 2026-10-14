# NixOS installation log for `moria`

This is the concise chronological record for the parallel NixOS installation.
Record material installation actions before every reboot: timestamp, action,
result, validation, status (`[PENDING]` or `[COMPLETED]`), and the required
next action. Do not include secrets or verbose command output.

## 2026-10-14T22:45:55Z — [PENDING] Initial installation

Verified the required installer ISO SHA-256
`81ec93d823a7ad40f58b14dfcf43de5d794a3aa956564301fa5fcdbe68459f88` through
the mapped Ventoy device. Verified target filesystem and partition UUIDs,
approximately 198 GiB estimated free space, Fedora subvolumes, and the
existing ESP. Verified Snapper snapshot 2 and the ESP archive checksum
`bc10532b864f1611b95daf46aacfe870c3f66518c6e894b3d3b800515c9f6b2a`.

Created only `nixos-root` (ID 635) and `nixos-home` (ID 636), mounted them at
`/mnt` and `/mnt/home` with `compress=zstd:1`, and mounted ESP UUID `38B5-8386`
at `/mnt/boot`. Generated hardware configuration and validated flake revision
`b7396669dcb51df423c31b9c2b38168e6336e8be` with `nix flake check`.

Required next action: run the root installation, verify bootloader files and a
separate NixOS UEFI entry while preserving Fedora and Windows, then update this
entry to `[COMPLETED]` only after the bootability gate passes. No reboot yet.
