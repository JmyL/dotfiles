# Userscripts

Source-of-truth copies for Tampermonkey (Vivaldi / Brave).

## Install / update

1. Open the `.user.js` file in Vivaldi (or copy its contents).
2. Tampermonkey should offer to install/update; confirm.
3. On `app.circleci.com`, allow notifications if prompted.

## Scripts

- `circleci-tab-status.user.js` — replace the CircleCI favicon with a status-colored circle + white `C` (yellow/green/red); system notify when a watched run finishes. Does not touch `document.title` (plays nice with tab-number extensions).
- `slack-hover-reactions.user.js` — add `:white_check_mark:` and `:merged:` to Slack's message hover reaction bar (the `+1` / `eyes` / `rocket` row). Click toggles the reaction through Slack's own API.
