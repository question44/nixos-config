"""Tests for scripts/erebor-tasks. Run: python3 -m unittest discover scripts/tests

`nix flake check` runs them through checks.x86_64-linux.tasks.
"""

import importlib.machinery
import importlib.util
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "erebor-tasks"
loader = importlib.machinery.SourceFileLoader("erebor_tasks", str(SCRIPT))
spec = importlib.util.spec_from_loader("erebor_tasks", loader)
et = importlib.util.module_from_spec(spec)
loader.exec_module(et)

CHANGELOG = textwrap.dedent("""\
    # Change log

    This file holds the current month (November 2026); add new entries below.

    # Did a thing — 2026-11-02

    Text.
    """)


def task(status="OPEN", date="review: 2026-11-20", extra="", body="Body.", task_id="SYS-001", title="Title"):
    return f"---\nstatus: {status}\n{date}\n{extra}---\n\n# {task_id} — {title}\n\n{body}\n"


class Repo:
    """A throwaway repository with a changelog and a tasks/ directory."""

    def __init__(self, git=False):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "flake.nix").write_text("{}\n")
        (self.root / "tasks").mkdir()
        (self.root / "SYSTEM_CHANGELOG.md").write_text(CHANGELOG)
        if git:
            self.git("init", "-q", "-b", "master")
            self.git("config", "user.email", "test@example.invalid")
            self.git("config", "user.name", "test")

    def write(self, rel, text):
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def git(self, *args, cwd=None):
        return subprocess.run(["git", *args], cwd=cwd or self.root, check=True,
                              capture_output=True, text=True).stdout

    def commit(self, message="commit"):
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def run(self, *args, cwd=None):
        return subprocess.run([sys.executable, str(SCRIPT), *args], cwd=cwd or self.root,
                              capture_output=True, text=True)

    def check(self):
        return self.run("check", str(self.root))


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.repo = Repo()

    def tearDown(self):
        self.repo.tmp.cleanup()

    def assertFails(self, needle):
        result = self.repo.check()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(needle, result.stdout)

    def test_valid_repo_passes(self):
        self.repo.write("tasks/SYS-001.md", task(body="See [log](../SYSTEM_CHANGELOG.md#did-a-thing--2026-11-02)."))
        result = self.repo.check()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_duplicate_id(self):
        self.repo.write("tasks/SYS-001.md", task())
        self.repo.write("tasks/archive/2026-10/SYS-001.md",
                        task(status="DONE", date="closed: 2026-10-03", body="[log](../../../SYSTEM_CHANGELOG.md)"))
        self.assertFails("duplicate ID SYS-001")

    def test_heading_must_match_file(self):
        self.repo.write("tasks/SYS-001.md", task(task_id="SYS-002"))
        self.assertFails("heading must be")

    def test_open_task_needs_review_date(self):
        self.repo.write("tasks/SYS-001.md", task(date=""))
        self.assertFails("needs a review date")

    def test_epic_and_children_must_agree(self):
        self.repo.write("tasks/SYS-001.md", task(extra="children: SYS-002\n"))
        self.repo.write("tasks/SYS-002.md", task(task_id="SYS-002"))
        self.assertFails("child SYS-002 does not name it as epic")

    def test_broken_link_and_anchor(self):
        self.repo.write("tasks/SYS-001.md", task(body="[a](SYS-009.md) [b](../SYSTEM_CHANGELOG.md#nope)"))
        result = self.repo.check()
        self.assertIn("broken link SYS-009.md", result.stdout)
        self.assertIn("no anchor #nope", result.stdout)

    def test_link_into_tasks_from_elsewhere(self):
        self.repo.write("tasks/SYS-001.md", task())
        self.repo.write("SYSTEM_CONTEXT.md", "[x](tasks/SYS-007.md)\n")
        self.assertFails("broken link tasks/SYS-007.md")

    def test_link_to_removed_todo_file(self):
        self.repo.write("tasks/SYS-001.md", task())
        self.repo.write("README.md", "[todo](SYSTEM_TODO.md#sys-001)\n")
        self.assertFails("link to removed SYSTEM_TODO.md")

    def test_archive_due_uses_changelog_month(self):
        self.repo.write("tasks/SYS-001.md", task(status="DONE", date="closed: 2026-10-30",
                                                  body="[log](../SYSTEM_CHANGELOG.md)"))
        self.assertFails("run `scripts/erebor-tasks archive`")

    def test_closed_task_warnings(self):
        self.repo.write("tasks/SYS-001.md", task(status="DONE", date="closed: 2026-11-03",
                                                  body="\n".join(f"line {i}" for i in range(20))))
        result = self.repo.check()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("shrink it to a stub", result.stdout)
        self.assertIn("without a link to its changelog entry", result.stdout)


class SlugTests(unittest.TestCase):
    def test_github_slugs(self):
        cases = {
            "[COMPLETED] Umbriel action arguments in rcmd and helpers — 2026-11-04":
                "completed-umbriel-action-arguments-in-rcmd-and-helpers--2026-11-04",
            "Ambilight remembers \"off\" across HyperHDR restarts — 2026-11-07":
                "ambilight-remembers-off-across-hyperhdr-restarts--2026-11-07",
            "`desktop-password` also sets the Time Machine password — 2026-11-07":
                "desktop-password-also-sets-the-time-machine-password--2026-11-07",
        }
        for heading, slug in cases.items():
            self.assertEqual(et.github_slug(heading), slug)

    def test_repeated_headings_and_explicit_anchors(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "a.md"
            path.write_text('# Same\n\n# Same\n\n<a id="record-1"></a>\n\n```\n# not a heading\n```\n')
            self.assertEqual(et.anchors_of(path), {"same", "same-1", "record-1"})


class ArchiveTests(unittest.TestCase):
    def test_archive_moves_and_rewrites_links(self):
        repo = Repo()
        self.addCleanup(repo.tmp.cleanup)
        # Pretend today is in November by giving tasks October/November closes.
        repo.write("tasks/SYS-001.md", task(status="DONE", date="closed: 2000-01-05",
                                             body="[log](../SYSTEM_CHANGELOG.md#did-a-thing--2026-11-02)"))
        repo.write("tasks/SYS-002.md", task(task_id="SYS-002", body="Needs [SYS-001](SYS-001.md)."))
        repo.write("SYSTEM_CONTEXT.md", "See [SYS-001](tasks/SYS-001.md).\n")
        result = repo.run("archive")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((repo.root / "tasks/archive/2000-01/SYS-001.md").exists())
        self.assertFalse((repo.root / "tasks/SYS-001.md").exists())
        self.assertIn("(archive/2000-01/SYS-001.md)", (repo.root / "tasks/SYS-002.md").read_text())
        self.assertIn("(tasks/archive/2000-01/SYS-001.md)", (repo.root / "SYSTEM_CONTEXT.md").read_text())
        moved = (repo.root / "tasks/archive/2000-01/SYS-001.md").read_text()
        self.assertIn("(../../../SYSTEM_CHANGELOG.md#did-a-thing--2026-11-02)", moved)


class ReservationTests(unittest.TestCase):
    def setUp(self):
        self.repo = Repo(git=True)
        self.addCleanup(self.repo.tmp.cleanup)
        self.repo.write("tasks/SYS-001.md", task())
        self.repo.commit()

    def test_next_sees_other_branches_and_worktrees(self):
        self.repo.git("branch", "other")
        other = Path(self.repo.tmp.name + "-wt")
        self.addCleanup(lambda: subprocess.run(["rm", "-rf", str(other)]))
        self.repo.git("worktree", "add", "-q", str(other), "other")
        (other / "tasks" / "SYS-005.md").write_text(task(task_id="SYS-005"))  # uncommitted
        self.assertEqual(self.repo.run("next").stdout.strip(), "SYS-006")

    def test_concurrent_new_runs_get_distinct_ids(self):
        runs = [subprocess.Popen([sys.executable, str(SCRIPT), "new", f"Task {i}"], cwd=self.repo.root,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                for i in range(6)]
        outputs = [p.communicate()[0].splitlines()[0] for p in runs]
        self.assertEqual(len(set(outputs)), 6, outputs)
        reserved = (self.repo.root / ".git" / et.RESERVED).read_text().splitlines()
        self.assertEqual(len(reserved), 6)

    def test_reserved_ids_are_skipped(self):
        first = self.repo.run("new", "One").stdout.splitlines()[0]
        os.remove(self.repo.root / first)  # abandoned: the reservation stays
        self.assertEqual(self.repo.run("next").stdout.strip(), "SYS-003")


if __name__ == "__main__":
    unittest.main()
