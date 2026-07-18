# tmux + iPhone Codex Monitoring: Cost-Minimal Setup

This note describes the lowest-cost way to monitor and steer a Codex CLI session
from an iPhone when Codex is running inside tmux on the PC.

## Baseline

- PC: reuse existing `tmux`, `ssh`, and Codex CLI.
- Network: use Tailscale's free tier.
- Phone SSH: use Termius free features, or another free iOS SSH client.
- Push notifications: use a free private `ntfy.sh` topic.
- Operation model: connect from iPhone over SSH, then attach to the Codex tmux
  session.

```sh
tmux new -A -s codex
```

From the phone:

```sh
ssh sungsik@<tailscale-hostname-or-ip>
tmux attach -t codex
```

## PC Side

- Install and run Tailscale on the host OS, not only inside a toolbox.
- Sign in to the same tailnet as the iPhone.
- Enable SSH access through Tailscale. Do not expose SSH directly to the public
  internet.
- Run Codex CLI inside a named tmux session, preferably `codex`.
- Optional: add a `phone-notify` helper that sends short messages to a private
  `ntfy.sh` topic.
- Optional: connect Codex CLI notifications or lifecycle hooks to
  `phone-notify` for completion, permission request, and blocked-state alerts.

## iPhone Side

- Install Tailscale and sign in to the same tailnet.
- Install Termius, or another iOS SSH client that supports key-based SSH.
- Add the PC as a host using its Tailscale MagicDNS name or Tailscale IP.
- Use SSH key auth or Tailscale SSH.
- Install ntfy and subscribe to the same private topic used by `phone-notify`.
- Allow iOS notifications for ntfy.

## Cost Controls

- Stay on the Tailscale free tier unless team management, advanced policy, or
  larger device/user limits are actually needed.
- Avoid paid SSH app features unless sync or advanced terminal features are
  worth the subscription.
- Use the free `ntfy.sh` public service for lightweight notifications.
- Avoid ntfy Pro or a self-hosted VPS unless notification volume, privacy, or
  reliability requirements justify it.
- Keep the PC awake only when remote access is needed.
- Treat Codex usage as separate from this setup; it still counts against the
  existing Codex plan or API usage limits.

## Quick Verification

- Send a test notification from the PC and confirm it appears on the iPhone.
- Connect the iPhone to Tailscale and SSH into the PC.
- Run `tmux new -A -s codex` on the PC and attach from the iPhone.
- Start a short Codex task and confirm the tmux view updates correctly.
- If notification hooks are added later, trigger a short Codex turn and confirm
  the expected ntfy alert arrives.
