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
