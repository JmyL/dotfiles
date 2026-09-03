#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(
    os.environ.get("HERDR_RENAME_FIRST_TAB", Path.home() / ".local/bin/herdr-rename-first-tab")
)

MOCK_HERDR = r"""#!/usr/bin/env bash
set -euo pipefail
log="${HERDR_LOG:?}"
printf '%s\n' "$*" >>"$log"
case "$1 $2" in
"workspace list")
  cat "${HERDR_WORKSPACE_LIST:?}"
  ;;
"tab list")
  cat "${HERDR_TAB_LIST:?}"
  ;;
"tab rename")
  ;;
*)
  echo "unexpected herdr $*" >&2
  exit 1
  ;;
esac
"""


class HerdrRenameFirstTabTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.herdr = self.root / "herdr"
        self.herdr.write_text(MOCK_HERDR, encoding="utf-8")
        self.herdr.chmod(self.herdr.stat().st_mode | stat.S_IEXEC)
        self.log = self.root / "herdr.log"
        self.ws_list = self.root / "workspaces.json"
        self.tab_list = self.root / "tabs.json"

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(self) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["HERDR"] = str(self.herdr)
        env["HERDR_LOG"] = str(self.log)
        env["HERDR_WORKSPACE_LIST"] = str(self.ws_list)
        env["HERDR_TAB_LIST"] = str(self.tab_list)
        return subprocess.run(
            [str(SCRIPT)],
            check=False,
            text=True,
            capture_output=True,
            env=env,
        )

    def write_state(self, workspaces: list[dict], tabs: list[dict] | None = None) -> None:
        self.ws_list.write_text(
            json.dumps({"result": {"workspaces": workspaces}}), encoding="utf-8"
        )
        self.tab_list.write_text(
            json.dumps({"result": {"tabs": tabs or []}}), encoding="utf-8"
        )

    def herdr_calls(self) -> list[str]:
        if not self.log.exists():
            return []
        return self.log.read_text(encoding="utf-8").splitlines()

    def test_renames_first_tab_from_project_label(self):
        self.write_state(
            [
                {"workspace_id": "w48", "focused": True, "label": "project: dotfiles"},
                {"workspace_id": "w54", "focused": False, "label": "project: ree-drive"},
            ],
            [
                {"tab_id": "w48:t1", "number": 1, "label": "old"},
                {"tab_id": "w48:t2", "number": 2, "label": "other"},
            ],
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls(),
            ["workspace list", "tab list --workspace w48", "tab rename w48:t1 dotfiles"],
        )

    def test_strips_dir_prefix_and_uses_lowest_tab_number(self):
        self.write_state(
            [{"workspace_id": "w2", "focused": True, "label": "dir: notes"}],
            [
                {"tab_id": "w2:t2", "number": 2, "label": "later"},
                {"tab_id": "w2:t1", "number": 1, "label": "first"},
            ],
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.herdr_calls()[-1],
            "tab rename w2:t1 notes",
        )

    def test_keeps_plain_workspace_label(self):
        self.write_state(
            [{"workspace_id": "w7", "focused": True, "label": "issue-empty-lobby"}],
            [{"tab_id": "w7:t1", "number": 1}],
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.herdr_calls()[-1], "tab rename w7:t1 issue-empty-lobby")

    def test_keeps_vdrive_prefix(self):
        self.write_state(
            [{"workspace_id": "w3", "focused": True, "label": "vdrive: abc123"}],
            [{"tab_id": "w3:t1", "number": 1}],
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.herdr_calls()[-1], "tab rename w3:t1 vdrive: abc123")

    def test_fails_without_focused_workspace(self):
        self.write_state([{"workspace_id": "w1", "focused": False, "label": "notes"}])
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no focused workspace", result.stderr)
        self.assertEqual(self.herdr_calls(), ["workspace list"])

    def test_fails_without_tabs(self):
        self.write_state(
            [{"workspace_id": "w1", "focused": True, "label": "notes"}],
            [],
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("workspace has no tabs", result.stderr)
        self.assertEqual(self.herdr_calls(), ["workspace list", "tab list --workspace w1"])


if __name__ == "__main__":
    unittest.main()
