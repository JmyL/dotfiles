# Userscripts

Source-of-truth copies for Tampermonkey (Brave).

## Install / update

1. Open the `.user.js` file in Brave (or copy its contents).
2. Tampermonkey should offer to install/update; confirm.
3. On `app.circleci.com`, allow notifications if prompted.

## Scripts

- `circleci-tab-status.user.js` — replace the CircleCI favicon with a status-colored circle + white `C` (yellow/green/red); system notify when a watched run finishes. Does not touch `document.title` (plays nice with tab-number extensions).
