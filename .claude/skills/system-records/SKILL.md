---
name: system-records
description: Use when writing or editing SYSTEM_CHANGELOG.md, a task under tasks/ or SYSTEM_CONTEXT.md - adding a changelog entry, the first entry of a new month (archive rollover), opening or closing a SYS-NNN task, recording a [PENDING] checkpoint, or deciding whether a change is complete.
---

# System records and task tracking

Nix files define the intended configuration. The three records hold what Nix
cannot: what changed and why, unfinished work, and live facts. Avoid
duplicating package, service, mount and version inventories in them.

## SYSTEM_CHANGELOG.md

- Records dated changes: what changed and why, activation outcome and
  generation when applicable, validation evidence, and explicit limits.
- Put new entries directly below its header.
- Record versions as dated evidence, not live state.
- Keep entries concise. Routine inspections belong in a related task's
  evidence when they resolve a question, not in a new changelog entry.
- Commit related records with the configuration change, in the same PR, and
  leave unrelated working-tree edits alone.

### Month rollover

`SYSTEM_CHANGELOG.md` holds only the current month. The first entry of a new
month first:

1. Moves the previous month's entries, unchanged and newest first, to
   `changelog/YYYY-MM.md`.
2. Adds that file to the header's list of earlier months.
3. Rewrites links to moved entries: `SYSTEM_CHANGELOG.md#…` becomes
   `changelog/YYYY-MM.md#…`; links inside the archive gain `../`.
4. Checks that every link still resolves.
5. Runs `scripts/erebor-tasks archive`, which moves tasks closed in earlier
   months to `tasks/archive/YYYY-MM/` and rewrites their links.

Archived months are history: do not edit them except to fix links.

## Tasks (`tasks/`)

- Unfinished work, one file per task (`tasks/SYS-NNN.md`);
  [tasks/README.md](../../../tasks/README.md) defines the format and rules.
  `scripts/erebor-tasks` shows the board; read it rather than every file.
- Create a task with `scripts/erebor-tasks new "Title"` (it reserves the ID
  under a lock), fill in a stable status, review date, concrete completion
  condition and evidence links, and land it in the PR of its work (see the
  parallel-agents skill).
- Statuses: OPEN for known work, ACTIVE for work underway, REVIEW for
  uncertain historical work, and DONE/CANCELLED with dated evidence or reason
  for closure. Group related tasks under an epic (`children:` / `epic:`).
- On closing (`scripts/erebor-tasks close SYS-NNN DONE`), shrink the task to
  a stub: outcome, untested parts, link to the changelog evidence.
- Keep IDs after closure; consolidate duplicate tasks by linking their
  records.
- When the changelog rolls over to a new month, also run
  `scripts/erebor-tasks archive`; `nix flake check` fails until it has run.

## SYSTEM_CONTEXT.md

- Holds only current non-declarative facts, recovery knowledge and verified
  pitfalls.
- Remove superseded facts; link tasks rather than copying their status.
- Check live state before using any historical recovery path.

## When a record is complete

- Complete an implementation record once its stated scope is activated and
  the required verification passes. A build alone does not prove activation.
- Track optional follow-ups and separate acceptance checks as linked tasks;
  explicitly required acceptance checks still block their own task's
  completion.
- Distinguish observed results, user confirmation, and untested behavior.

## [PENDING] and [RECORDED] entries

- Use `[PENDING]` changelog entries only for active material operations. Link
  the task. Before disruptive operations record the exact live generation,
  prechecks, recovery path, risks and next safe step, then read back the
  checkpoint. After verification, update the same entry with the outcome and
  resolve the task.
- Close failed or cancelled attempts with their actual result; do not imply
  success.
- Historical commands, approvals and checkpoints are evidence, not a current
  action queue. Resolve obsolete next-step instructions; preserve their dated
  context where useful. Never blindly replay an old reboot, activation or
  disk operation.
- `[RECORDED]` legacy entries have uncertain outcomes and link to a REVIEW
  task; reconcile newer evidence before doing system work.
