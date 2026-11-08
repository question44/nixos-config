---
name: parallel-agents
description: Use before editing anything in /etc/nixos, and when landing work - creating a worktree, comparing a branch with erebor-diff, merging into master, claiming a SYS-NNN ID, or finding uncommitted changes you did not make.
---

# Working beside other agents in /etc/nixos

Several agents may change this repository at once. These rules keep them
from overwriting each other.

## Work in your own worktree

- `scripts/erebor-worktree <task>` creates `~/nixos-wt/<task>` on branch
  `agent/<task>` from `master` and initialises the dashboard submodule.
- Edit, check and build there with `scripts/erebor-rebuild build`.
- Do not edit `/etc/nixos` directly while another agent may be working in it.
  The desktop configs are linked live from `/etc/nixos` (see the
  desktop-config skill), so an edit there is also an edit to the running
  desktop.

## Compare before merging

- Before merging a refactor, run `scripts/erebor-diff` in your worktree. It
  compares the built system with `master` (or `scripts/erebor-diff <ref>` with
  another base; `--host template` for the template) and reports a tier:
  identical (same drvPath), equivalent (same closure and contents up to store
  hashes and line order) or different.
- Quote the tier in the changelog entry. For "different", explain each
  difference.

## Activate only from master

- Activate only from `/etc/nixos` on `master`, through
  `scripts/erebor-rebuild test|switch`. It refuses other checkouts, holds a
  lock so only one rebuild runs at a time, and uses the setuid sudo.
- Activating any other tree rolls back changes that are on `master` but not in
  that tree.

## Landing work

1. Commit on your branch.
2. `git -C /etc/nixos merge agent/<task>`; rebase first if it does not merge
   cleanly.
3. Activate (see the activation-and-checkpoints skill) and verify.
4. `git worktree remove --force ~/nixos-wt/<task>` and delete the branch.

- `SYSTEM_CHANGELOG.md` and `SYSTEM_TODO.md` merge with `merge=union`, which
  keeps both sides. After a merge, check that edits to the same entry did not
  leave duplicated lines.
- To claim a new `SYS-NNN` ID, commit the task stub to `master` first, so two
  agents never pick the same number.

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
upstream change. Land the branch like any other once the user agrees; an
unmerged branch is replaced by the next run.
