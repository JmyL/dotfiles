---
name: pi-extension-portability
description: Guidance for writing or editing Pi custom extensions. Use when creating, reviewing, or modifying files under ~/.pi/agent/extensions, .pi/agent/extensions, or chezmoi dot_pi/agent/extensions to avoid non-portable absolute paths and environment-specific imports.
---

# Pi Extension Portability

When writing or editing Pi custom extensions, keep them portable across machines, usernames, Node versions, and install locations.

## Rules

- Do not import from absolute paths under a home directory, such as `/home/...`, `/var/home/...`, `~/.nvm/...`, or `~/.npm-global/...`.
- Do not import directly from version-specific Node installation paths such as `.nvm/versions/node/v*/lib/node_modules/...`.
- Prefer package imports:
  - `@earendil-works/pi-coding-agent`
  - `@earendil-works/pi-tui`
  - other extension dependencies by package name
- If a dependency is required, mention that the package must be installed instead of hardcoding where it exists on the current machine.
- Avoid checked-in machine-specific paths in extension source files, config files, and chezmoi-managed copies.

## Preferred imports

Use:

```ts
import { DynamicBorder, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Key, SelectList, Text, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
```

Not:

```ts
import type { ExtensionAPI } from "/home/user/.nvm/versions/node/v25.8.1/lib/node_modules/@earendil-works/pi-coding-agent/dist/index.d.ts";
import { Key } from "/home/user/.nvm/versions/node/v25.8.1/lib/node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui/dist/index.js";
```

For third-party helpers, use package imports:

```ts
import { someHelper } from "some-package/path.js";
```

and tell the user to install `some-package` if it is missing.

## Review checklist

Before finishing Pi extension changes, scan edited extension paths for hardcoded machine paths:

```bash
rg -n '(/home/|/var/home/|\.nvm/versions|\.npm-global|node_modules/.*/dist|from "/)' ~/.pi/agent/extensions .pi/agent/extensions ~/.local/share/chezmoi/dot_pi/agent/extensions 2>/dev/null
```

If matches are intentional, explain why. Otherwise replace them with package imports or relative paths within the extension package.
