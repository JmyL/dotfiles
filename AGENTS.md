# Global workflow rules

## General change hygiene

- Before editing a project, read the nearest applicable `AGENTS.md` and the relevant
  project documentation or build manifest.
- Preserve unrelated user changes in the working tree; inspect `git status` before and
  after edits.
- After a change, run the smallest relevant validation command and report clearly if
  validation could not be run.
- Use test-driven development by default for behavior changes and bug fixes: first add
  or update the smallest automated test that demonstrates the desired behavior (and
  would fail without the fix), then implement the change and run that test. If a test
  is impractical (for example, hardware-only or visual behavior), state why and use
  the closest repeatable verification instead.
- When creating a Dockerfile for the user-global `dev` tool, read
  `~/.local/bin/DEV-CONTAINER-IMAGE.md`; it is the global image contract and applies
  across repositories.

## Checking a recent command or build failure

When asked about a command that just ran, first check the current herdr context:

1. Confirm `HERDR_ENV=1`. If it is set, run `herdr pane list` and identify panes whose
   `cwd` or `foreground_cwd` matches the relevant working directory.
2. Read those panes with
   `herdr pane read <pane-id> --source recent-unwrapped --lines 120`.
   Prefer the shell pane's scrollback for the exact command and complete output; inspect
   agent or editor panes only as needed.
   `--source detection` can narrow the returned terminal region, but it is not a
   structured "last command plus result" API and may omit the command line.
3. To isolate only the latest command transcript, scan the returned text from the
   bottom upward for the shell-start prompt block: a line containing the basename of
   the pane's `foreground_cwd` and shell context, immediately followed by the input line
   ending in the prompt marker `❯`. This two-line structure is the shell-start match;
   do not match an isolated `❯` in output. If no match is visible in the first 120 lines,
   retry with 240, 360, ... up to 1200 lines. If the bottommost prompt is the empty
   prompt printed after a command completed, skip it and use the preceding prompt block.
   Treat the text below that selected prompt, up to the next prompt block, as the latest
   command and its result. Analyze no older output.
4. Use `atuin search --limit 20` as a supplementary source for recent commands and
   timestamps. Atuin generally does not preserve the command's terminal output.
5. Report which source supplied each fact. Do not infer a failure result from atuin alone.

If herdr is unavailable or `HERDR_ENV` is not `1`, say that pane inspection was not
available and ask for the terminal output instead.
