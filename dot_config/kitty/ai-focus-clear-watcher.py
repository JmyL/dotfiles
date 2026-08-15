"""Clear pending AI notifications, and warp into the Herdr pane, on Kitty focus."""
import os
from pathlib import Path
from subprocess import DEVNULL, Popen
from typing import Any

from kitty.boss import Boss
from kitty.window import Window

_HOME_BIN = Path.home() / ".local/bin"
_CLEAR = _HOME_BIN / "ai-kitty-focus-clear"
_WARP = _HOME_BIN / "herdr-warp-on-window-focus"


def _spawn(argv: list[str]) -> None:
    try:
        Popen(argv, stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
    except OSError:
        return


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("focused"):
        return

    if _CLEAR.is_file():
        _spawn([str(_CLEAR), str(window.id)])
    if _WARP.is_file():
        _spawn([str(_WARP), "--pid", str(os.getpid()), "--title", window.title or ""])
