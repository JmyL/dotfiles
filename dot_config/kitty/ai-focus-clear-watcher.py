"""Clear pending non-tmux AI notifications when their kitty window gains focus."""
from subprocess import DEVNULL, Popen
from typing import Any

from kitty.boss import Boss
from kitty.window import Window


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("focused"):
        return

    Popen(
        ["ai-kitty-focus-clear", str(window.id)],
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
    )
