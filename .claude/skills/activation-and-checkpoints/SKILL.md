---
name: activation-and-checkpoints
description: Use before activating (nixos-rebuild test/switch via erebor-rebuild), rebooting, or doing anything that touches boot, the ESP, filesystems, subvolumes, storage or Windows - covers prechecks, Snapper snapshots, the reboot checkpoint, and verifying afterwards.
---

# Activation, reboots and storage safety

## Before changing the system

- Read the relevant Nix files and modules before editing them.
- When the change affects system state, boot, storage or services, check the
  current generation, mounts, boot entries and failed units first.
- Run `nix flake check` and `scripts/erebor-rebuild build` (or `dry-build`)
  before activation.
- Stop and ask the user when the change is ambiguous, conflicts with
  AGENTS.md, or could affect Windows, the ESP or user data.

## Activating

- `scripts/erebor-rebuild test` in your worktree, `switch` only from
  `/etc/nixos` on `master` after the PR has landed (see the parallel-agents
  skill). Both need the user's YubiKey or fingerprint.
- Validate live with `test` before landing. Use `switch` only when the change is
  verified and the user has requested activation, or activation is the normal
  completion of the task.
- After activation, verify the affected services, the generation, mounts and
  the user-facing behavior. Record the result in `SYSTEM_CHANGELOG.md` in the
  change's PR (see the system-records skill).

## Rebooting after a material change

1. Write a checkpoint in `SYSTEM_CHANGELOG.md` with the exact generation, the
   validation performed, current risks and the mandatory next action.
2. Read the checkpoint back.
3. Do not reboot with an unresolved pending safety check.
4. After the reboot, verify the generation, mounts, bootability, the affected
   services and the user-facing behavior, and record the result in a
   follow-up PR.

## Storage and boot safety

- Identify the target Btrfs filesystem by UUID
  `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and the ESP by filesystem UUID
  `38B5-8386`; never by transient `/dev/sdX` or `/dev/nvme…` names.
- Never run partitioning, formatting, signature-wiping or recursive deletion
  commands for this system without explicit user authorization and a reviewed
  recovery plan.
- Preserve Windows UEFI files and entries. Do not change the firmware default
  or remove another operating system's boot entry as part of routine
  maintenance.
- Before any material boot, ESP, filesystem, subvolume or reboot operation:
  create and verify an important Snapper snapshot when applicable, record a
  `[PENDING]` checkpoint (system-records skill), and verify the recovery path.
