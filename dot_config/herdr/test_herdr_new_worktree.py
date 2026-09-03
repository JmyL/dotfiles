#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get("HERDR_NEW_WORKTREE", Path.home() / ".local/bin/herdr-new-worktree"))

MOCK_HERDR = r"""#!/usr/bin/env bash
set -euo pipefail
log="${HERDR_LOG:?}"
printf '%s\n' "$*" >>"$log"
case "$1 $2" in
"pane current")
  cat "${HERDR_PANE_CURRENT:?}"
  ;;
"notification show" | "worktree create")
  ;;
*)
  echo "unexpected herdr $*" >&2
  exit 1
  ;;
esac
"""


class HerdrNewWorktreeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.herdr = self.root / "herdr"
        self.herdr.write_text(MOCK_HERDR, encoding="utf-8")
        self.herdr.chmod(self.herdr.stat().st_mode | stat.S_IEXEC)
        self.log = self.root / "herdr.log"
        self.pane_current = self.root / "pane.json"
        self.plain = self.root / "plain"
        self.plain.mkdir()
        self.repo = self.root / "repo"
        self.repo.mkdir()
        subprocess.run(["git", "init", str(self.repo)], check=True, capture_output=True)

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(
        self, *args: str, pane_cwd: str | None = None, extra_env: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        self.pane_current.write_text(
            json.dumps({"result": {"pane": {"cwd": pane_cwd or "", "foreground_cwd": pane_cwd or ""}}}),
            encoding="utf-8",
        )
        env = os.environ.copy()
        env["HERDR"] = str(self.herdr)
        env["HERDR_LOG"] = str(self.log)
        env["HERDR_PANE_CURRENT"] = str(self.pane_current)
        env.pop("HERDR_ACTIVE_PANE_CWD", None)
        if extra_env:
            env.update(extra_env)
        return subprocess.run(
            [str(SCRIPT), *args],
            check=False,
            text=True,
            capture_output=True,
            env=env,
        )

    def herdr_calls(self) -> list[str]:
        if not self.log.exists():
            return []
        return self.log.read_text(encoding="utf-8").splitlines()

    def test_usage(self):
        result = self.run_script("--unknown")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_notifies_when_cwd_is_not_git(self):
        result = self.run_script("--cwd", str(self.plain))
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.herdr_calls()
        self.assertTrue(any(c.startswith("notification show Worktree") for c in calls))
        self.assertFalse(any(c.startswith("worktree create") for c in calls))

    def test_creates_worktree_from_git_cwd(self):
        result = self.run_script("--cwd", str(self.repo))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            [f"worktree create --cwd {self.repo.resolve()} --focus"],
        )

    def test_passes_branch(self):
        result = self.run_script("--cwd", str(self.repo), "--branch", "feat")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            [f"worktree create --cwd {self.repo.resolve()} --branch feat --focus"],
        )

    def test_empty_branch_lets_herdr_name_it(self):
        result = self.run_script("--cwd", str(self.repo), "--branch", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            [f"worktree create --cwd {self.repo.resolve()} --focus"],
        )

    def test_uses_active_pane_cwd(self):
        result = self.run_script(extra_env={"HERDR_ACTIVE_PANE_CWD": str(self.plain)})
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.herdr_calls()
        self.assertTrue(any(c.startswith("notification show Worktree") for c in calls))
        self.assertFalse(any(c.startswith("pane current") for c in calls))

    def test_uses_pane_current_when_env_missing(self):
        result = self.run_script(pane_cwd=str(self.repo))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            [
                "pane current",
                f"worktree create --cwd {self.repo.resolve()} --focus",
            ],
        )

    def test_notifies_when_pane_cwd_missing(self):
        result = self.run_script(pane_cwd="")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.herdr_calls()
        self.assertIn("pane current", calls)
        self.assertTrue(any(c.startswith("notification show Worktree") for c in calls))
        self.assertFalse(any(c.startswith("worktree create") for c in calls))


if __name__ == "__main__":
    unittest.main()
