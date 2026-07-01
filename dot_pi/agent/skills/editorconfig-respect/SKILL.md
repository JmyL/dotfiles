---
name: editorconfig-respect
description: Use when creating or editing files in any project, especially scripts, config files, dotfiles, or source files. Ensures the agent checks applicable .editorconfig files and follows indentation, line ending, final newline, charset, and trimming rules before writing changes.
---

# Respect .editorconfig

When creating or editing files, check for applicable `.editorconfig` files and follow their formatting rules.

## Workflow

1. Before writing or significantly editing a file, look for `.editorconfig` files from the target file's directory upward to the project/root boundary.
   - Use `find`/`dirname`/`pwd` as needed.
   - Remember that nested `.editorconfig` files override parent rules.
   - Stop applying parent files when an `.editorconfig` contains `root = true`.
2. Determine the matching section for the target filename/path.
   - Apply global `[*]` rules plus more specific matching sections.
   - Later matching sections override earlier ones within the same file.
3. Follow common properties when writing content:
   - `indent_style`
   - `indent_size`
   - `tab_width`
   - `end_of_line`
   - `charset`
   - `trim_trailing_whitespace`
   - `insert_final_newline`
4. For shell scripts and executables, also preserve executable intent and shebang conventions, but do not ignore `.editorconfig` indentation/newline rules.
5. If no `.editorconfig` applies, infer style from surrounding files and existing file contents.

## Verification

After editing, verify when practical:

```bash
# show relevant files
find .. -name .editorconfig -print

# check target for trailing whitespace and final newline if relevant
```

Prefer minimal, targeted edits that preserve the existing style of the file.
