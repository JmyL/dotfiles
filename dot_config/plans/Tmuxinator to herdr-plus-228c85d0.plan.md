<!-- 228c85d0-d539-4a78-9477-7f2cd43f08ce -->
---
todos:
  - id: "write-personal"
    content: "Write/overwrite personal herdr-plus TOMLs (ask, blogging, dotfiles, EMail, forager-keymap, notes, nvim, vifm)"
    status: pending
  - id: "write-work"
    content: "Write work herdr-plus TOMLs for ree-drive, ree-teleport-ui, ree-vehicle-configs with ai (no -R)"
    status: pending
  - id: "chezmoi-track"
    content: "herdr-plus-chezmoi track-add all; commit/push personal and work repos"
    status: pending
isProject: false
---
# Tmuxinator → herdr-plus projects

## 변환 규칙

| tmuxinator | herdr-plus |
|---|---|
| `name` / `root` | `name` / `working_dir` |
| `windows[]` | `[[tabs]]` (순서 유지) |
| window name | `tabs.name` |
| single pane command | `tabs.command` |
| multi pane | `[[tabs.panes]]`; 첫 pane은 root, 이후 `split = "right"` (가로) 또는 `"down"` (세로) |
| `ai -R` | **`ai`만** (resume 제거) |
| `agent --mode=ask`, `nvim`, `v`, `vifm`, `aerc`, `tuxedo`, hugo 스크립트 | 그대로 |

라우팅은 기존 [`herdr-plus-chezmoi`](~/.local/bin/herdr-plus-chezmoi): `working_dir` ∈ `$HOME/projects` → work, 아니면 personal.  
생성 후 `herdr-plus-chezmoi install-toml` / `track-add`로 배치·커밋.

경로 정규화 (한 가지만):

- `EMail`의 `/var/home/sungsik/Downloads` → `~/Downloads` (크로스 머신)
- `~/Projects/...`(대문자, 이 머신에 없음)는 YAML 그대로 유지 → personal

기존 [`dotfiles.toml`](~/.config/herdr/plugins/config/cloudmanic.herdr-plus/projects/dotfiles.toml)은 tmuxinator `dotfiles`와 맞춰 **덮어씀** (nvim + ai 스플릿). [`herdr-plus-projects.toml`](~/.config/herdr/plugins/config/cloudmanic.herdr-plus/projects/herdr-plus-projects.toml) 메타 프로젝트는 유지.

## 생성할 프로젝트

**Personal** (`.../cloudmanic.herdr-plus/projects/` 실파일):

- `ask` — `/tmp`, tab `config` → `agent --mode=ask`
- `blogging` — `~/Projects/jmyl.github.io/`, tab `editor` ×3: `v` / `ai` (right) / hugo bash (down)
- `dotfiles` — `~/.config`, `editor` ×2: `nvim` / `ai` (right)
- `EMail` — `~/Downloads`, tabs `aerc`→`aerc`, `Files`→`vifm ~/Downloads ~/Dropbox`
- `forager-keymap` — `~/Projects/forager-zmk-config`, ×2: `v config/forager.keymap` / `ai` (right)
- `notes` — `~/Documents/Obsidian`, ×2: `nvim` / `tuxedo` (right)
- `nvim` — `~/.config/nvim`, ×2: `nvim` / `ai` (right)
- `vifm` — `~`, `vifm`

**Work** (`~/.config/work/herdr-plus/projects/` + discovery symlink):

- `ree-drive` — `/home/sungsik/projects/ree-drive` → `~/projects/ree-drive`, ×2: `nvim` / `ai`
- `ree-teleport-ui` — `~/projects/ree-teleport-ui`, ×2: `nvim` / `ai`
- `ree-vehicle-configs` — `~/projects/ree-vehicle-configs`, ×2: `nvim` / `ai`

예시 (ree-drive / dotfiles 공통 패턴):

```toml
name = "ree-drive"
working_dir = "~/projects/ree-drive"

[[tabs]]
name = "config"

[[tabs.panes]]
command = "nvim"

[[tabs.panes]]
command = "ai"
split = "right"
```

## 적용 절차

1. live TOML 작성 (personal 실파일 / work는 work canonical 경로)
2. work 항목: symlink + `herdr-plus-chezmoi track-add`
3. personal 항목: `herdr-plus-chezmoi track-add` (또는 `chezmoi add` + commit/push)
4. personal·work chezmoi 각각 커밋·푸시

tmuxinator YAML은 삭제하지 않음 (병행).
