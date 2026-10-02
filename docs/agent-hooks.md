---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# Running immosquare-cleaner as an AI agent hook

This page explains how `immosquare-cleaner --hook` finds the files an AI coding agent just edited, what it guarantees to the agent, and how to troubleshoot it. The configuration snippets for Claude Code, OpenAI Codex, Cursor and Gemini CLI are in the [README](../README.md#-hook-it-into-your-ai-agent); this page assumes one of them is in place.

## How the --hook mode finds the edited files

An agent hook does not receive the edited file as an argument: the agent pipes a JSON description of the edit on stdin. `immosquare-cleaner --hook` reads that JSON and looks for the edited paths in the field each agent uses:

| Agent                   | Where the edited path is read                                                                                    |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Claude Code, Gemini CLI | `tool_input.file_path`                                                                                           |
| OpenAI Codex            | The patch in `tool_input.command`: one `*** Update File:`, `*** Add File:` or `*** Move to:` line per file       |
| Cursor                  | `file_path` at the top level of the payload (`afterFileEdit` event)                                              |
| Kimi Code               | `tool_input.path`                                                                                                |
| Grok                    | `toolInput.file_path`                                                                                            |

A relative path is resolved against `tool_input.workdir` when Codex sends one, then against the payload's `cwd`. A Codex patch that touches several files gets each of them formatted; a `*** Delete File:` line is ignored, since there is nothing left to format.

## What the hook guarantees to the agent

A hook runs after every single edit, so a hook that fails or talks too much disrupts the whole session. `immosquare-cleaner --hook` follows four rules in every agent:

- **It never blocks the agent.** The exit status is always `0`, whatever happens: a non-zero status can interrupt the agent or show an error after each edit.
- **It skips what it does not handle.** A deleted file, a directory, a symlink, a file with no formatter (`.env`, `LICENSE`, images), an empty or invalid payload: nothing is done and nothing is reported. A symlink is never followed, so an edit cannot reformat a file outside the project.
- **It keeps stdout empty.** Codex and Gemini CLI read a hook's stdout as its JSON answer, so every linter report goes to stderr instead.
- **It formats in place.** The agent's file changes on disk right after its edit; Claude Code detects it and rereads the file before its next edit.

Each edit costs one formatter run, typically under two seconds for ESLint or RuboCop and much less for gofmt, shfmt or taplo.

## Troubleshooting an immosquare-cleaner hook that does nothing

Run the hook by hand with the payload the agent would send. It prints the formatter's report on stderr, which the agent normally hides:

```bash
echo '{"tool_input":{"file_path":"src/api.ts"}}' | immosquare-cleaner --hook
```

| Symptom                                      | Cause and fix                                                                                                                                                                                                                                       |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The agent reports `command not found`        | Agents run hooks in a non-interactive shell, where rvm, rbenv or asdf may not be loaded. Use the absolute path of the command in the hook: `which immosquare-cleaner`.                                                                              |
| Nothing changes and nothing is printed       | The file has no formatter (see the supported formats in the README), or the payload does not carry the path where the agent's row above says. Check the payload the agent really sends.                                                             |
| A Shell, Rust, Go or TOML file is left as is | Its formatter is not installed: the manual run prints the install command (`brew install shfmt`, `rustup component add rustfmt`, `brew install go`, `brew install taplo`).                                                                          |
| `invalid option: --hook`                     | The installed gem predates the hook mode. Upgrade with `gem update immosquare-cleaner`, or update the version locked in the project's `Gemfile.lock`.                                                                                               |

## Limits of the hook mode

The hook mode covers the edit tools of each agent. Two cases stay outside it:

- **Codex edits made through a shell command** (`sed -i`, a script that rewrites a file) carry no file path in their payload. Only `apply_patch` edits are formatted; point the Codex hook matcher at `apply_patch` only.
- **One Ruby per hook.** The hook runs with the Ruby that launched `immosquare-cleaner`. On a machine where each project has its own Ruby and Bundler setup, the hook command has to select that environment before calling `bundle exec immosquare-cleaner --hook`.

The `-p` option (wait, then clean a copy) is meant for editor on-save hooks, where the IDE may still be writing the file. An agent hook runs after the edit is complete and does not need it.
