# NixOS installation log for `moria`

This is the concise chronological record for the parallel NixOS installation.
Record material installation actions before every reboot: timestamp, action,
result, validation, status (`[PENDING]` or `[COMPLETED]`), and the required
next action. Do not include secrets or verbose command output.

## 2026-10-14T23:12:14Z — [COMPLETED] Complete first-boot Secret Service configuration

First boot is operational: Niri, Noctalia, Ghostty, ungoogled Chromium under
Wayland, NVIDIA, networking, native display mode, and PipeWire were verified.
Found the Secret portal still selected the GNOME backend while GNOME Keyring
was disabled; Oo7 was only installed as a client package. Added declarative
Oo7 daemon/portal wiring and validated the configuration with
`nixos-rebuild dry-build --flake /etc/nixos#moria`.

Activated the configuration with `sudo nixos-rebuild switch`. Verified the Oo7
daemon owns `org.freedesktop.secrets` with `cap_ipc_lock`, the generated Niri
portal configuration selects Oo7, GNOME Keyring is absent, and no system units
are failed.

## 2026-10-14T23:21:18Z — [COMPLETED] Final first-boot reboot acceptance

Pre-reboot checkpoint written to `SYSTEM_CHANGELOG.md`. Active generation is
`dqc84r5k9jijlk2z8y4c1s2wi5wclnpi`; the target Btrfs and ESP identifiers are
unchanged. Reboot completed at 23:16 UTC and the system returned to the
working NixOS generation with the expected root and home subvolumes. Fedora
was then selected from firmware and reported by the user as booting normally
and remaining intact. Initial installation and first-boot acceptance are
complete.

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
The `janzon` account password was set interactively after installation; no
password material is recorded here.

Created and verified separate UEFI entry `Boot0005* NixOS` pointing to
`\\EFI\\systemd\\systemd-bootx64.efi`. Fedora and Windows UEFI entries and
their `EFI/fedora`, `EFI/moria`, and `EFI/Microsoft` paths remain present.
BootOrder leaves Fedora first and NixOS last. The bootability gate passed.

Required next action: reboot and explicitly select `NixOS` from firmware for
first-boot acceptance. Do not change the firmware default until acceptance
checks pass.
