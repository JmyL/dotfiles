# Dotfiles notes

## GPG key backup for `pass`

`~/.password-store` entries are encrypted with GPG. The encrypted files can be
shared through dotfiles, but another machine also needs a matching GPG private
key to decrypt them.

### Export on the machine that can already read `pass`

```sh
mkdir -p ~/Private/gpg-backup
chmod 700 ~/Private/gpg-backup

gpg --export --armor "Sungsik Nam <jmyl@me.com>" \
  > ~/Private/gpg-backup/sungsik-public.asc

gpg --export-secret-keys --armor "Sungsik Nam <jmyl@me.com>" \
  > ~/Private/gpg-backup/sungsik-private.asc
chmod 600 ~/Private/gpg-backup/sungsik-private.asc
```

Copy `sungsik-private.asc` only through a trusted channel. Do not commit it to
chezmoi, git, or any public/shared dotfiles repository.

### Import on another machine

```sh
gpg --import sungsik-public.asc
gpg --import sungsik-private.asc
```

Optionally mark the key as trusted:

```sh
gpg --edit-key "Sungsik Nam <jmyl@me.com>"
# gpg> trust
# choose 5 = ultimate
# gpg> quit
```

Then verify that `pass` can decrypt an entry:

```sh
pass show mail/icloud/jmyl
```

### Cleanup

After importing, remove the temporary private-key export from the target
machine unless it is stored in a secure backup location:

```sh
shred -u sungsik-private.asc 2>/dev/null || rm -f sungsik-private.asc
```

## Atuin shell history

Atuin is a candidate shell-history upgrade for interactive shells. It provides a
searchable, context-aware history database and can optionally sync history across
machines.

Useful setup checklist:

```sh
# Install atuin with the preferred machine-specific package manager.
atuin --version

# Import existing shell history before enabling shell integration.
atuin import auto

# Enable sync only if desired.
atuin login
atuin sync
```

Typical shell integration belongs in the relevant shell config, for example
`~/.config/fish/config.fish`, `~/.bashrc`, or `~/.zshrc`. Keep any Atuin sync
credentials or session keys out of chezmoi-tracked files.

Related paths:

- Atuin config: `~/.config/atuin/config.toml`
- Atuin data/state: `~/.local/share/atuin/`
- Atuin cache/state may vary by version and package source.

## Google calendar/contact sync

Google Calendar and Contacts are synchronized with `vdirsyncer`.

Related files:

- Setup notes: `~/.config/calendar-contacts-vdirsyncer.md`
- vdirsyncer config: `~/.config/vdirsyncer/config`
- khal config: `~/.config/khal/config`
- khard config: `~/.config/khard/khard.conf`
- aerc address-book integration: `~/.config/aerc/aerc.conf`
- optional user timer:
  - `~/.config/systemd/user/vdirsyncer.service`
  - `~/.config/systemd/user/vdirsyncer.timer`

Secrets and tokens are intentionally not tracked by chezmoi:

- OAuth client ID: `pass show mail/gmail/google-oauth-client-id`
- OAuth client secret: `pass show mail/gmail/google-oauth-client-secret`
- vdirsyncer OAuth tokens: `~/.local/state/vdirsyncer/google-*-token`

Manual sync:

```sh
vdirsyncer sync
```

Use `discover` only when Google calendar/contact collections change:

```sh
vdirsyncer discover
vdirsyncer sync
```

Enable the optional timer manually when desired:

```sh
systemctl --user daemon-reload
systemctl --user enable --now vdirsyncer.timer
systemctl --user list-timers vdirsyncer.timer
```

Check sync logs:

```sh
journalctl --user -u vdirsyncer.service
```
