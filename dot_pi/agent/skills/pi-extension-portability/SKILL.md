---
name: pi-extension-portability
description: Guidance for writing or editing Pi custom extensions. Use when creating, reviewing, or modifying files under ~/.pi/agent/extensions, .pi/agent/extensions, or chezmoi dot_pi/agent/extensions to avoid non-portable absolute paths and environment-specific imports.
---

# Pi Extension Portability

Keep Pi custom extensions portable across machines, usernames, Node versions, and install locations.

## Rules

- Never import from machine-specific paths: `/home/...`, `/var/home/...`, `~/.nvm/...`, `~/.npm-global/...`, or versioned `node_modules/.../dist/...` paths.
- Prefer package imports:
  ```ts
  import { DynamicBorder, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
  import { Key, SelectList, Text } from "@earendil-works/pi-tui";
  ```
- For dependencies, use package names and tell the user to install missing packages; do not hardcode where they are installed.
- Be cautious with non-public imports like `some-package/lib/internal.js`: verify Pi can resolve them and that they do not import old package names or absolute paths internally.
- If a small helper dependency causes resolution/portability issues, inline the helper code in the extension.

## Checklist

Scan extension sources, including chezmoi copies:

```bash
rg -n '(/home/|/var/home/|\.nvm/versions|\.npm-global|node_modules/.*/dist|from "/)' ~/.pi/agent/extensions .pi/agent/extensions ~/.local/share/chezmoi/dot_pi/agent/extensions 2>/dev/null
```

Load-test active extensions after changes:

```bash
PI_SKIP_VERSION_CHECK=1 timeout 8s pi --no-session
```

Fix or explain any matches/errors before finishing.
