---
name: parallel-agents
description: Use before editing anything in /etc/nixos, and when landing work - creating a worktree, comparing a branch with erebor-diff, testing a branch, landing it on master through a squash-merged PR, creating a SYS-NNN task, or finding uncommitted changes you did not make.
---

# Working beside other agents in /etc/nixos

Several agents may change this repository at once. These rules keep them
from overwriting each other.

## Work in your own worktree

- `scripts/erebor-worktree <task>` creates `~/nixos-wt/<task>` on branch
  `agent/<task>` from `origin/master` and initialises the submodules.
- Edit, check and build there with `scripts/erebor-rebuild build`.
- Do not edit `/etc/nixos` directly while another agent may be working in it.
  The desktop configs are linked live from `/etc/nixos` (see the
  desktop-config skill), so an edit there is also an edit to the running
  desktop. Never commit there: `/etc/nixos` only fast-forwards to
  `origin/master`.

## Compare before merging

- Before merging a refactor, run `scripts/erebor-diff` in your worktree. It
  compares the built system with `master` (or `scripts/erebor-diff <ref>` with
  another base; `--host template` for the template) and reports a tier:
  identical (same drvPath), equivalent (same closure and contents up to store
  hashes and line order) or different.
- Quote the tier in the changelog entry. For "different", explain each
  difference.

## Testing and activating

`scripts/erebor-rebuild` holds a lock so only one rebuild runs at a time and
uses the setuid sudo.

- `test` runs in your worktree on an `agent/*` branch that contains
  `origin/master` (rebase first), so nothing landed is rolled back. Another
  agent's `test` replaces yours; both reset on the next `switch` or reboot.
- Live-linked configs (desktop-config skill) come from `/etc/nixos` even then:
  they change only when the PR lands.
- `switch` runs only in `/etc/nixos` on `master` equal to `origin/master`,
  that is after the PR has landed.

## Landing work: one squash-merged PR per change

Each change lands as one PR, squashed into one commit on `master`. The PR
holds everything about the change: configuration, the `SYSTEM_CHANGELOG.md`
entry with its test evidence, and new or closed task files.

1. In your worktree: build, `scripts/erebor-diff`, and `erebor-rebuild test`
   when the change needs activation; verify it.
2. Write the changelog entry from the test (generation numbers come only with
   `switch`; record the tested toplevel path instead), `nix fmt`, commit.
3. `git fetch && git rebase origin/master`; if that changed anything, rebuild
   and retest. Check the union-merged `SYSTEM_CHANGELOG.md` for duplicated
   lines.
4. `scripts/erebor-land --title "<area>: <change>" --body-file <file>` pushes
   the branch, opens the PR (title = squashed commit subject; body ends with
   the attribution line), squash-merges it and fast-forwards `/etc/nixos`.
   That puts live-linked configs live.
5. In `/etc/nixos`: `scripts/erebor-rebuild switch` when the change needs
   activation; check it behaves as tested.
6. Remove the worktree and `git branch -D agent/<task>` (squashed branches
   are not ancestors of `master`, so `-d` refuses).

- Something found after landing (a failed post-switch check, a reboot
  checkpoint's outcome) is a new small PR, never a commit on `master`.
- `git commit`, `merge`, `reset` or `rebase` on `master` are refused by the
  hooks in `.githooks/` (`core.hooksPath`); `EREBOR_ALLOW_MASTER=1` overrides
  them only when the user asks. GitHub refuses pushes to `master` too.
- Create a new task with `scripts/erebor-tasks new`, which reserves the ID
  under a lock (no two agents on this machine get the same number), and land
  it in the PR of the work it belongs to; a task on its own is a small PR.

## Other agents' changes

- Uncommitted changes in `/etc/nixos` that you did not make belong to another
  agent. Leave them out of your commits and do not reset them;
  `erebor-rebuild` lists them before activating.

## The weekly update branch

`erebor-update-branch.timer` (user unit, `my.updateBranch`) runs
`scripts/erebor-update-branch` weekly: it recreates `~/nixos-wt/flake-update`
on `agent/flake-update` from `master`, updates nixpkgs and home-manager,
builds erebor, runs `erebor-diff` against `master`, and commits the lock with
the report as the commit message (also in
`~/.local/state/erebor-update/report.md`). It never activates. To bump the
pinned third-party inputs too, run it by hand with `--pinned` and review each
upstream change. Land the branch like any other (a PR) once the user agrees; an
unmerged branch is replaced by the next run.
