"""Clear pending AI notifications, and warp into the Herdr pane, on Kitty focus."""
import os
from pathlib import Path
from subprocess import DEVNULL, Popen
from typing import Any

from kitty.boss import Boss
from kitty.window import Window

_WARP = Path.home() / ".local/bin/herdr-warp-on-window-focus"


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("focused"):
        if _WARP.is_file():
            Popen(
                [str(_WARP), "--cancel"],
                stdin=DEVNULL,
                stdout=DEVNULL,
                stderr=DEVNULL,
            )
        return

    Popen(
        ["ai-kitty-focus-clear", str(window.id)],
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
    )
    if _WARP.is_file():
        Popen(
            [str(_WARP), "--pid", str(os.getpid()), "--title", window.title or ""],
            stdin=DEVNULL,
            stdout=DEVNULL,
            stderr=DEVNULL,
        )
