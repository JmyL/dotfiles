"""Clear pending AI notifications, and warp into the Herdr pane, on Kitty focus."""
import os
from pathlib import Path
from subprocess import DEVNULL, Popen
from typing import Any

from kitty.boss import Boss
from kitty.window import Window

_LAUNCHER = Path.home() / ".local/bin/dev-launcher"
_HERDR_WARP_ON_WINDOW_FOCUS = (
    Path.home()
    / ".config/herdr/plugins/local/herdr-pane-mouse-warp/herdr-warp-on-window-focus"
)


def _spawn(argv: list[str]) -> None:
    try:
        Popen(argv, stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
    except OSError:
        return


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("focused"):
        return
    if not _LAUNCHER.is_file():
        return

    launcher = str(_LAUNCHER)
    _spawn([launcher, "ai-kitty-focus-clear", str(window.id)])
    if not _HERDR_WARP_ON_WINDOW_FOCUS.is_file():
        return
    _spawn(
        [
            str(_HERDR_WARP_ON_WINDOW_FOCUS),
            "--pid",
            str(os.getpid()),
            "--title",
            window.title or "",
        ]
    )
