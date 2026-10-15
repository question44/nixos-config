# NixOS system change log for `moria`

Record completed NixOS configuration changes and material pending operations
here. Prefix active work **[PENDING]**; change that entry to **[COMPLETED]**,
**[BLOCKED]**, or **[CANCELLED]** with its final result. Do not record
secrets, routine read-only inspections, or one-off command failures.

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
