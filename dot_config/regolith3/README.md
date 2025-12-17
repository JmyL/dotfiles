Find customized packages with:

```bash
ls /usr/share/doc/ | grep regolith
dpkg -S /usr/share/regolith/i3/config.d/55_session_keybindings
```

As far as I know,

```bash
sudo apt remove regolith-wm-base-launchers regolith-i3-ilia regolith-wm-navigation regolith-i3-session
```

would be sufficient.

Set the default session:

```
sudo vim /var/lib/AccountsService/users/$USERNAME
```

Add or update these lines:

```
[Desktop]
Session=regolith-x11
```
