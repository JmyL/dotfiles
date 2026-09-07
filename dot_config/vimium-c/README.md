# Vimium C settings

Chezmoi-tracked copy of a Vimium C Export (`settings.json`).
Live settings are read and written over Vivaldi localhost CDP.
`vimium-c-sync` starts `~/.local/bin/vivaldi-stable` when CDP is down.
Do **not** track `~/.config/vivaldi/`.

## Apply chezmoi to this browser

After `chezmoi update` (or when asked to 반영 the tracked settings):

```sh
vimium-c-sync incoming
vimium-c-sync apply
```

`incoming` with no file pulls the live extension (or the newest
`~/Downloads/vimium_c-*.json`). After a chezmoi update, tracked wins
unless you keep local mappings with `merge` / `adopt`.

## Keep this machine's mappings

```sh
vimium-c-sync incoming
vimium-c-sync merge            # or: vimium-c-sync adopt
```

`adopt` strips export time and Chromium version so later compares stay
about real settings (key mappings, exclusions, …).
