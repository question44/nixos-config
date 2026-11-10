# Tasks for `erebor`

Unfinished work, one file per task: `tasks/SYS-NNN.md`. History and dated
evidence belong in [SYSTEM_CHANGELOG.md](../SYSTEM_CHANGELOG.md); recovery
knowledge belongs in [SYSTEM_CONTEXT.md](../SYSTEM_CONTEXT.md). Tasks closed in
an earlier month are in `archive/YYYY-MM/`.

See the board with `scripts/erebor-tasks` (open work, grouped by status, epics
with their children). `scripts/erebor-tasks --all` adds closed tasks,
`scripts/erebor-tasks show SYS-NNN` prints one. `scripts/erebor-tasks list --json`
prints counts, overdue reviews, epic progress and open tasks for the dashboard
hub's admin-only Tasks card (`my.taskBoard`). `nix flake check` runs
`scripts/erebor-tasks check` (IDs, headers, epics, links and their anchors)
and the tests in `scripts/tests/`. `check` also warns about closed tasks that
are long or have no changelog link.

## Statuses

- **OPEN:** a specific remaining task or unverified result is known.
- **ACTIVE:** work is underway; include the current checkpoint, recovery path
  and next safe step for disruptive operations.
- **REVIEW:** migrated historical work; reconcile later evidence and current
  intent before treating it as something to execute.
- **DONE / CANCELLED:** closed with dated evidence or a reason; the ID is kept.

Each task has one stable ID. Do not renumber or reuse IDs. Link related tasks
instead of copying their instructions. No review task authorizes a reboot,
activation, storage change, secret archive or graphical-session interruption.
Earlier approvals remain bounded by their original scope and safety
preconditions.

## File format

```markdown
---
status: OPEN            # OPEN, ACTIVE, REVIEW, DONE or CANCELLED
review: 2026-11-22      # next review date (open statuses)
closed: 2026-11-08      # DONE/CANCELLED only, instead of review
epic: SYS-087           # optional parent epic
children: SYS-075, SYS-076   # an epic's tasks
kind: check             # optional: an acceptance check rather than work
---

# SYS-NNN — Title

What is wanted and why, what remains, and links to evidence.

Done when: a concrete completion condition.
```

The ID comes from the file name and the title from the heading; status lives
only in the header. Link to other tasks by file (`[SYS-076](SYS-076.md)`), and
to other records with relative paths (`../SYSTEM_CHANGELOG.md#…`).

An epic is a task with `children:`; each child names it in `epic:`. The check
keeps both sides in step. An epic closes when all its children are closed and
its own completion condition is met.

## Adding a task

1. `scripts/erebor-tasks new "Title"` creates `tasks/SYS-NNN.md`. Under a lock
   in the shared git directory it picks the next ID not used on any branch,
   in any worktree's files, or in `.git/erebor-tasks-reserved`, and records
   it there, so concurrent runs on this machine never get the same ID.
2. Fill in what is wanted, the plan if known, and a concrete completion
   condition. For active work, record the next safe step and any recovery
   checkpoint.
3. Commit the file on your branch; it lands with that branch's PR (a task on
   its own is a small PR). An abandoned reservation only skips a number.

## Closing a task

1. `scripts/erebor-tasks close SYS-NNN DONE` (or `CANCELLED`) sets the status
   and the closed date.
2. Shrink the body to a stub: one or two sentences on the outcome (observed
   result, user confirmation, or the reason for cancelling), what was left
   untested, and a link to the changelog entry holding the evidence. Do not
   keep plans or progress notes the changelog already records. Never infer
   successful activation from a build alone.
3. Required acceptance checks block completion; optional follow-ups get their
   own ID.

## Monthly archive

Tasks closed in an earlier month than the one `SYSTEM_CHANGELOG.md`'s header
names must be archived; `nix flake check` fails until they are. After the
changelog rolls over to a new month, run `scripts/erebor-tasks archive`: it
moves those tasks, unchanged, to `archive/YYYY-MM/` and rewrites every link
to them. Archived tasks are history: do not edit them
except to fix links. Tasks closed before the 2026-11-08 restructure were
archived with their full text.
