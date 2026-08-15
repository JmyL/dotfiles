#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
import subprocess
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


def load_mod():
    path = Path(__file__).with_name("herdr-warp-on-window-focus")
    loader = SourceFileLoader("herdr_warp_on_window_focus", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


MOD = load_mod()


class DecideActionTest(unittest.TestCase):
    def test_recent_pane_warp_skips_even_with_cache(self):
        self.assertEqual(
            MOD.decide_action(
                recent_pane=True,
                cache=(10, 20, 800, 600),
                cache_size_ok=True,
                is_herdr=True,
                title_herdr=True,
            ),
            "skip",
        )

    def test_matching_cache_replays(self):
        self.assertEqual(
            MOD.decide_action(
                recent_pane=False,
                cache=(10, 20, 800, 600),
                cache_size_ok=True,
                is_herdr=False,
                title_herdr=False,
            ),
            "replay",
        )

    def test_resized_cache_recomputes(self):
        self.assertEqual(
            MOD.decide_action(
                recent_pane=False,
                cache=(10, 20, 800, 600),
                cache_size_ok=False,
                is_herdr=False,
                title_herdr=False,
            ),
            "compute",
        )

    def test_herdr_child_without_cache_computes(self):
        self.assertEqual(
            MOD.decide_action(
                recent_pane=False,
                cache=None,
                cache_size_ok=False,
                is_herdr=True,
                title_herdr=False,
            ),
            "compute",
        )

    def test_plain_kitty_skips(self):
        self.assertEqual(
            MOD.decide_action(
                recent_pane=False,
                cache=None,
                cache_size_ok=False,
                is_herdr=False,
                title_herdr=False,
            ),
            "skip",
        )

    def test_title_fallback_computes(self):
        self.assertEqual(
            MOD.decide_action(
                recent_pane=False,
                cache=None,
                cache_size_ok=False,
                is_herdr=False,
                title_herdr=True,
            ),
            "compute",
        )


class CacheHelpersTest(unittest.TestCase):
    def test_parse_cache(self):
        self.assertEqual(MOD.parse_cache("12 34\n800 600\n"), (12, 34, 800, 600))
        self.assertIsNone(MOD.parse_cache("12 34\n"))
        self.assertIsNone(MOD.parse_cache("nope\n"))

    def test_cache_matches_rect(self):
        cache = (1, 2, 800, 600)
        self.assertTrue(MOD.cache_matches_rect(cache, {"width": 800, "height": 600}))
        self.assertFalse(MOD.cache_matches_rect(cache, {"width": 801, "height": 600}))
        self.assertTrue(MOD.cache_matches_rect(cache, None))

    def test_title_has_herdr(self):
        self.assertTrue(MOD.title_has_herdr("herdr"))
        self.assertTrue(MOD.title_has_herdr("codex: x (herdr-lab)"))
        self.assertFalse(MOD.title_has_herdr("codex: Implement title sync (app-ios)"))


class RecentPaneWarpFileTest(unittest.TestCase):
    def setUp(self):
        self._old = MOD.WARP_DIR
        self.td = tempfile.TemporaryDirectory()
        MOD.WARP_DIR = Path(self.td.name)

    def tearDown(self):
        MOD.WARP_DIR = self._old
        self.td.cleanup()

    def test_reads_stamp(self):
        (MOD.WARP_DIR / "last-pane-warp").write_text("900\n", encoding="utf-8")
        self.assertTrue(MOD.recent_pane_warp(now_ms=1000, skip_ms=200))
        self.assertFalse(MOD.recent_pane_warp(now_ms=1200, skip_ms=200))


class KittyHasHerdrTest(unittest.TestCase):
    def setUp(self):
        self.td = tempfile.TemporaryDirectory()
        self._old = MOD.PROC_ROOT
        MOD.PROC_ROOT = Path(self.td.name)

    def tearDown(self):
        MOD.PROC_ROOT = self._old
        self.td.cleanup()

    def _proc(self, pid: int, comm: str, child_pids: list[int] | None = None, cmdline: str = "") -> None:
        proc = MOD.PROC_ROOT / str(pid)
        task = proc / "task" / str(pid)
        task.mkdir(parents=True)
        (proc / "comm").write_text(f"{comm}\n", encoding="utf-8")
        raw = cmdline.replace(" ", "\0") + "\0" if cmdline else f"{comm}\0"
        (proc / "cmdline").write_bytes(raw.encode())
        children = " ".join(str(c) for c in (child_pids or []))
        (task / "children").write_text(f"{children}\n" if children else "", encoding="utf-8")

    def test_finds_direct_herdr_child(self):
        self._proc(10, "kitty", [11])
        self._proc(11, "herdr")
        self.assertTrue(MOD.kitty_has_herdr(10))

    def test_ignores_plain_shell(self):
        self._proc(10, "kitty", [11])
        self._proc(11, "bash")
        self.assertFalse(MOD.kitty_has_herdr(10))

    def test_finds_nested_herdr(self):
        self._proc(10, "kitty", [11])
        self._proc(11, "bash", [12])
        self._proc(12, "herdr")
        self.assertTrue(MOD.kitty_has_herdr(10))


class WarpOnFocusScriptTest(unittest.TestCase):
    def test_disable_env_is_noop(self):
        script = Path(__file__).with_name("herdr-warp-on-focus")
        result = subprocess.run(
            [str(script)],
            env={**os.environ, "HERDR_WARP_ON_FOCUS": "0"},
            check=False,
        )
        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
