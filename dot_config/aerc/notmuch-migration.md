# aerc notmuch/maildir migration plan

Goal: move aerc from direct IMAP access to a local Maildir synced by isync/mbsync and indexed by notmuch, so threaded/conversation views can include both INBOX and sent mail.

## Tools

Install/check:

```sh
command -v mbsync
command -v notmuch
```

Fedora/toolbox package names:

```sh
sudo dnf install isync notmuch
```

`isync` provides the `mbsync` command.

## Proposed data flow

```text
iCloud IMAP
  -> mbsync/isync
~/Mail/JmyL/          # local Maildir
  -> notmuch new
~/Mail/JmyL/.notmuch  # notmuch database
  -> aerc notmuch backend
```

## mbsync config draft

Create `~/.mbsyncrc`:

```ini
IMAPAccount icloud
Host imap.mail.me.com
User jmyl@me.com
PassCmd "pass show mail/icloud/jmyl"
SSLType IMAPS
Port 993

IMAPStore icloud-remote
Account icloud

MaildirStore icloud-local
Path ~/Mail/JmyL/
Inbox ~/Mail/JmyL/INBOX
SubFolders Verbatim

Channel icloud
Far :icloud-remote:
Near :icloud-local:
Patterns *
Create Both
SyncState *
Expunge None
```

Initial sync:

```sh
mkdir -p ~/Mail/JmyL
mbsync icloud
```

Start with `Expunge None` for safety until delete/archive behavior is verified.

## notmuch setup

Run:

```sh
notmuch setup
```

Suggested answers:

```text
Full name: Sungsik Nam
Primary email: jmyl@me.com
Additional emails: jmyl@icloud.com, jmyl@mac.com
Mail archive: /var/home/sungsik/Mail/JmyL
```

Index and verify:

```sh
notmuch new
notmuch count '*'
notmuch search tag:inbox | head
```

## Optional notmuch post-new hook

If tags need normalization, create `~/.notmuch/hooks/post-new`:

```sh
#!/bin/sh
notmuch tag +inbox -- folder:INBOX
notmuch tag +sent -- folder:"Sent Messages"
notmuch tag +draft -- folder:Drafts
notmuch tag +archive -- folder:Archive
notmuch tag +trash -- folder:"Deleted Messages" or folder:Trash
notmuch tag +spam -- folder:Junk
```

Make executable:

```sh
chmod +x ~/.notmuch/hooks/post-new
```

Adjust folder queries after inspecting the actual Maildir layout and notmuch query behavior.

## aerc query-map draft

Create `~/.config/aerc/notmuch-queries`:

```ini
INBOX=tag:inbox
Sent=tag:sent
Drafts=tag:draft
Archive=tag:archive
Unread=tag:unread
Flagged=tag:flagged
All=*
Conversations=tag:inbox or tag:sent
```

`Conversations` is intended for views where sent and received messages appear together in threads.

## aerc accounts.conf draft

Back up the current IMAP account first:

```sh
cp ~/.config/aerc/accounts.conf ~/.config/aerc/accounts.conf.imap.bak
```

Then change `[JmyL]` to use notmuch:

```ini
[JmyL]
source             = notmuch://~/Mail/JmyL
query-map          = ~/.config/aerc/notmuch-queries
maildir-store      = ~/Mail/JmyL
check-mail         = 5m
check-mail-cmd     = mbsync icloud && notmuch new
check-mail-timeout = 5m

outgoing           = smtp://jmyl%40me.com@smtp.mail.me.com:587
outgoing-cred-cmd  = pass show mail/icloud/jmyl

from               = Sungsik Nam <jmyl@me.com>
aliases            = jmyl@me.com, jmyl@icloud.com, jmyl@mac.com

archive            = Archive
copy-to            = Sent Messages
postpone           = Drafts
```

Keep `reply-to-self=false` in `aerc.conf`.

## Verification checklist

1. `pass show mail/icloud/jmyl` works.
2. `mbsync icloud` completes without deleting server mail.
3. `notmuch new` indexes messages.
4. `notmuch search tag:inbox` returns expected messages.
5. aerc starts with the notmuch account.
6. INBOX and Sent views appear from `query-map`.
7. `Conversations` plus thread mode shows both received and sent mail in one thread.
8. Sending mail still works through SMTP.
9. Archive/delete behavior is tested on non-important messages before trusting it.
