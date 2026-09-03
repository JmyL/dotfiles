#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get("HERDR_OPEN_PROJECT", Path.home() / ".local/bin/herdr-open-project"))

MOCK_HERDR = r"""#!/usr/bin/env bash
set -euo pipefail
log="${HERDR_LOG:?}"
printf '%s\n' "$*" >>"$log"
case "$1 $2" in
"workspace list")
  cat "${HERDR_WORKSPACE_LIST:?}"
  ;;
"pane list")
  cat "${HERDR_PANE_LIST:?}"
  ;;
"workspace focus")
  ;;
"workspace create")
  cat "${HERDR_CREATE_JSON:?}"
  ;;
"worktree create" | "notification show")
  ;;
"tab rename" | "tab create" | "pane split" | "pane rename" | "pane run")
  if [[ "$1 $2" == "tab create" ]]; then
    printf '%s\n' '{"result":{"root_pane":{"pane_id":"w9:p2"}}}'
  elif [[ "$1 $2" == "pane split" ]]; then
    printf '%s\n' '{"result":{"pane":{"pane_id":"w9:p1"}}}'
  fi
  ;;
*)
  echo "unexpected herdr $*" >&2
  exit 1
  ;;
esac
"""

DOTFILES_TOML = """name = "dotfiles"
working_dir = "{cwd}"

[[tabs]]
name = "dotfiles"

[[tabs.panes]]
command = "nvim"

[[tabs.panes]]
command = "ai"
split = "right"
"""


class HerdrOpenProjectTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.projects = self.root / "projects"
        self.projects.mkdir()
        self.cwd = self.root / "dotfiles-cwd"
        self.cwd.mkdir()
        (self.projects / "dotfiles.toml").write_text(
            DOTFILES_TOML.format(cwd=self.cwd), encoding="utf-8"
        )
        self.herdr = self.root / "herdr"
        self.herdr.write_text(MOCK_HERDR, encoding="utf-8")
        self.herdr.chmod(self.herdr.stat().st_mode | stat.S_IEXEC)
        self.log = self.root / "herdr.log"
        self.ws_list = self.root / "workspaces.json"
        self.pane_list = self.root / "panes.json"
        self.create_json = self.root / "create.json"
        self.create_json.write_text(
            json.dumps(
                {
                    "result": {
                        "workspace": {"workspace_id": "w9"},
                        "root_pane": {"pane_id": "w9:p0"},
                    }
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(self, *args: str) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["HERDR"] = str(self.herdr)
        env["HERDR_PLUS_PROJECTS_DIR"] = str(self.projects)
        env["HERDR_LOG"] = str(self.log)
        env["HERDR_WORKSPACE_LIST"] = str(self.ws_list)
        env["HERDR_PANE_LIST"] = str(self.pane_list)
        env["HERDR_CREATE_JSON"] = str(self.create_json)
        return subprocess.run(
            [str(SCRIPT), *args],
            check=False,
            text=True,
            capture_output=True,
            env=env,
        )

    def write_state(self, workspaces: list[dict], panes: list[dict] | None = None) -> None:
        self.ws_list.write_text(
            json.dumps({"result": {"workspaces": workspaces}}), encoding="utf-8"
        )
        self.pane_list.write_text(
            json.dumps({"result": {"panes": panes or []}}), encoding="utf-8"
        )

    def herdr_calls(self) -> list[str]:
        if not self.log.exists():
            return []
        return self.log.read_text(encoding="utf-8").splitlines()

    def init_git(self, path: Path | None = None) -> None:
        subprocess.run(
            ["git", "init", str(path or self.cwd)],
            check=True,
            capture_output=True,
        )

    def test_usage(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_unknown_project(self):
        self.write_state([])
        result = self.run_script("missing")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no project named 'missing'", result.stderr)

    def test_focuses_existing_project_label(self):
        self.write_state([{"workspace_id": "w1K", "label": "project: dotfiles"}])
        result = self.run_script("dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            ["workspace list", "workspace focus w1K"],
        )

    def test_ignores_other_project_at_same_cwd(self):
        self.write_state(
            [{"workspace_id": "w2", "label": "project: other"}],
            [
                {
                    "workspace_id": "w2",
                    "cwd": str(self.cwd),
                    "foreground_cwd": str(self.cwd),
                }
            ],
        )
        result = self.run_script("dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.herdr_calls()
        self.assertNotIn("workspace focus w2", calls)
        self.assertTrue(any(c.startswith("workspace create") for c in calls))

    def test_creates_missing_project_and_applies_tabs(self):
        self.write_state([])
        result = self.run_script("dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.herdr_calls()
        self.assertIn("workspace list", calls)
        self.assertNotIn("pane list", calls)
        self.assertTrue(any(c.startswith("workspace create") for c in calls))
        self.assertIn("tab rename w9:t1 dotfiles", calls)
        self.assertIn("pane split w9:p0 --direction right --no-focus", calls)
        self.assertIn("pane run w9:p0 nvim", calls)
        self.assertIn("pane run w9:p1 ai", calls)

    def test_worktree_creates_from_project_cwd(self):
        self.init_git()
        self.write_state([{"workspace_id": "w1K", "label": "project: dotfiles"}])
        result = self.run_script("--worktree", "--branch", "feat", "dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            [f"worktree create --cwd {self.cwd} --branch feat --focus"],
        )

    def test_worktree_empty_branch_lets_herdr_name_it(self):
        self.init_git()
        self.write_state([])
        result = self.run_script("--worktree", "--branch", "", "dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            [f"worktree create --cwd {self.cwd} --focus"],
        )

    def test_worktree_applies_branch_prefix(self):
        self.init_git()
        (self.projects.parent / "config.toml").write_text(
            '[worktree]\nbranch_prefix = "sungsik/"\n', encoding="utf-8"
        )
        result = self.run_script("--worktree", "--branch", "feat", "dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls()[-1],
            f"worktree create --cwd {self.cwd} --branch sungsik/feat --focus",
        )

    def test_worktree_keeps_qualified_branch(self):
        self.init_git()
        (self.projects.parent / "config.toml").write_text(
            '[worktree]\nbranch_prefix = "sungsik/"\n', encoding="utf-8"
        )
        result = self.run_script("--worktree", "--branch", "sungsik/feat", "dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls()[-1],
            f"worktree create --cwd {self.cwd} --branch sungsik/feat --focus",
        )

    def test_worktree_requires_tty_without_branch(self):
        self.init_git()
        result = self.run_script("--worktree", "dotfiles")
        self.assertEqual(result.returncode, 1)
        self.assertIn("need a terminal to prompt", result.stderr)
        self.assertEqual(self.herdr_calls(), [])

    def test_worktree_notifies_when_not_git_repo(self):
        result = self.run_script("--worktree", "--branch", "feat", "dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.herdr_calls()
        self.assertTrue(any(c.startswith("notification show Worktree") for c in calls))
        self.assertFalse(any(c.startswith("worktree create") for c in calls))

    def test_worktree_unknown_project(self):
        result = self.run_script("--worktree", "--branch", "feat", "missing")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no project named 'missing'", result.stderr)
        self.assertEqual(self.herdr_calls(), [])


if __name__ == "__main__":
    unittest.main()
