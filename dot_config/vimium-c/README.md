# Vimium C settings

Chezmoi-tracked copy of a Vimium C **Export** (`settings.json`).
The extension still needs a manual Import / Export; this directory is the
cross-machine source of truth.

Do **not** track `~/.config/vivaldi/` profile state.

## Other-PC flow

1. `chezmoi update` (or pull + apply) so `settings.json` is current.
2. Export the local Vimium C settings (default name `~/Downloads/vimium_c-*.json`).
3. Compare, then keep tracked, take incoming, or merge:

```sh
vimium-c-sync export --open
vimium-c-sync incoming
vimium-c-sync merge            # or: vimium-c-sync adopt
vimium-c-sync import --open
```

4. In Options → Backup / Restore, Import `~/.config/vimium-c/settings.json`.
5. If the merge/adopt changed the tracked file, `chezmoi add` already ran;
   commit and push the personal chezmoi repo.

## First machine

Export once, then:

```sh
vimium-c-sync adopt
```

`adopt` strips export time and Chromium version so later compares stay
about real settings (key mappings, exclusions, …).
