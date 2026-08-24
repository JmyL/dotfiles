"""Clear pending AI notifications, and warp into the Herdr pane, on Kitty focus."""
import json
import os
from pathlib import Path
from subprocess import DEVNULL, Popen
from typing import Any

from kitty.boss import Boss
from kitty.window import Window

_LAUNCHER = Path.home() / ".local/bin/dev-launcher"
_HERDR_PLUGINS_JSON = Path.home() / ".config/herdr/plugins.json"


def _plugin_script(plugin_id: str, script_name: str) -> Path | None:
    try:
        plugins = json.loads(_HERDR_PLUGINS_JSON.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(plugins, list):
        return None
    for plugin in plugins:
        if not isinstance(plugin, dict):
            continue
        if plugin.get("plugin_id") != plugin_id or not plugin.get("enabled", True):
            continue
        root = plugin.get("plugin_root")
        if isinstance(root, str) and root:
            return Path(root) / script_name
    return None


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
    warp = _plugin_script("herdr-pane-mouse-warp", "herdr-warp-on-window-focus")
    if warp is None or not warp.is_file():
        return
    _spawn(
        [
            str(warp),
            "--pid",
            str(os.getpid()),
            "--title",
            window.title or "",
        ]
    )
