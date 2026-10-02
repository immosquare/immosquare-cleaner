---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# immosquare-cleaner

**One formatter for your whole repository — TypeScript, Rust, Go, Shell, TOML, Markdown, CSS and more — wired into your AI coding agent so every file it writes comes out clean.**

[![Gem Version](https://img.shields.io/gem/v/immosquare-cleaner)](https://rubygems.org/gems/immosquare-cleaner) [![Downloads](https://img.shields.io/gem/dt/immosquare-cleaner)](https://rubygems.org/gems/immosquare-cleaner) [![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

![immosquare-cleaner --hook fixing the indentation and 36 RuboCop offenses of a file written by Claude Code](assets/demo.gif)

AI agents write code fast, but not consistently: wrong indentation, mixed quotes, stray semicolons. immosquare-cleaner gives every file to the right formatter with one shared configuration. Plug it into Claude Code, Codex, Cursor or Gemini CLI once, and every edit is formatted the moment the agent makes it. It also cleans a single file, or a whole repository in one run.

## 🧰 Supported formats

immosquare-cleaner picks the formatter from the file's extension or name. Each format has its own page with the rules applied and real before/after examples.

| Format                             | Files                                                                    | Formatter                  | Details                                     |
| ---------------------------------- | ------------------------------------------------------------------------ | -------------------------- | ------------------------------------------- |
| JavaScript, TypeScript             | `.js` `.mjs` `.cjs` `.jsx` `.ts` `.tsx`                                  | ESLint                     | [javascript.md](docs/javascript.md)         |
| Rust, TOML                         | `.rs`, `.toml`                                                           | rustfmt, taplo             | [rust-toml.md](docs/rust-toml.md)           |
| Go                                 | `.go`                                                                    | gofmt                      | [go.md](docs/go.md)                         |
| Shell                              | `.sh` `.bash` `.zsh` `.bashrc` `.zshrc`…                                 | shfmt                      | [shell.md](docs/shell.md)                   |
| Markdown                           | `.md`                                                                    | built in                   | [markdown.md](docs/markdown.md)             |
| CSS, YAML, JSON, Vue, GraphQL      | `.css` `.scss` `.less` `.yml` `.json` `.vue` `.graphql` `.hbs`           | Prettier, built in (JSON)  | [other-formats.md](docs/other-formats.md)   |
| Ruby, ERB, Rails locales           | `.rb` `Gemfile` `.html.erb` `.js.erb` `locales/*.yml`…                   | RuboCop, erb_lint          | [ruby-erb.md](docs/ruby-erb.md)             |

The style is opinionated and shared across formats: 2-space indentation wherever the tool allows it, double quotes, no semicolons in JavaScript, aligned imports and assignments. Go keeps gofmt's tabs, which gofmt does not let you change.

## ⚡ Quick start

immosquare-cleaner is a command-line tool distributed as a Ruby gem: it needs Ruby 3.2.6+ and [bun](https://bun.sh/), which runs ESLint and Prettier.

```bash
gem install immosquare-cleaner
immosquare-cleaner src/api.ts   # one file
immosquare-cleaner .            # the whole repository
```

The formatters for Shell, Rust, Go and TOML are only needed for those files: `brew install shfmt go taplo` and `rustup component add rustfmt`. When one is missing, immosquare-cleaner prints its install command and leaves the file untouched.

## 🤖 Hook it into your AI agent

With `--hook`, immosquare-cleaner reads the JSON payload an agent sends after each edit and formats the edited files. The hook never blocks the agent (it always exits `0`), skips files it does not handle, and keeps stdout empty. How it finds the files and how to troubleshoot it are in [agent-hooks.md](docs/agent-hooks.md).

**Claude Code** — `.claude/settings.json` in the project, or `~/.claude/settings.json` for every project:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "hooks": [{"type": "command", "command": "immosquare-cleaner --hook"}]
      }
    ]
  }
}
```

**OpenAI Codex** — `~/.codex/hooks.json`. Every file listed in an `apply_patch` edit is formatted; Codex may ask you to trust the new hook first.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "apply_patch",
        "hooks": [{"type": "command", "command": "immosquare-cleaner --hook"}]
      }
    ]
  }
}
```

**Cursor** — `.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [{"command": "immosquare-cleaner --hook"}]
  }
}
```

**Gemini CLI** — `.gemini/settings.json`:

```json
{
  "hooks": {
    "AfterTool": [
      {
        "matcher": "write_file|replace",
        "hooks": [{"type": "command", "command": "immosquare-cleaner --hook"}]
      }
    ]
  }
}
```

## ✨ Before and after

Each example is a real run: red is what an agent wrote, green is what immosquare-cleaner wrote back. Every format page has more.

**TypeScript** — quotes, semicolons and indentation fixed, imports and assignments aligned:

```diff
-import {User} from './types'
-import {request} from './http'
+import {User}    from "./types"
+import {request} from "./http"
 export const getUser = async (id: number): Promise<User> => {
-    const options = {method: 'GET', retries: 3};
-    let response = await request(`/users/${id}`, options);
-    return response as User;
+  const options = {method: "GET", retries: 3}
+  let response  = await request(`/users/${id}`, options)
+  return response as User
 }
```

**Rust** — rustfmt with a 2-space indent, unless the project has its own `rustfmt.toml`:

```diff
 use std::collections::HashMap;
-fn count(words:&[&str])->HashMap<&str,usize>{
-let mut map=HashMap::new();
-    for w in words { *map.entry(*w).or_insert(0)+=1; }
-  map
+fn count(words: &[&str]) -> HashMap<&str, usize> {
+  let mut map = HashMap::new();
+  for w in words {
+    *map.entry(*w).or_insert(0) += 1;
+  }
+  map
 }
```

**Go** — `gofmt -s`, simplifications included:

```diff
 package main
+
 import "fmt"
-type P struct{X,Y int}
-func main(){
-  ps:=[]P{P{1,2},P{3,4}}
-  s:="hello"
-    fmt.Println(ps,s[1:len(s)])
+
+type P struct{ X, Y int }
+
+func main() {
+	ps := []P{{1, 2}, {3, 4}}
+	s := "hello"
+	fmt.Println(ps, s[1:])
 }
```

## 🛠️ Command-line options

The `immosquare-cleaner` command takes a file or a directory. Given a directory, it cleans every source file listed by `git ls-files`, in parallel, and skips build output, lock files and vendored folders: see [repository.md](docs/repository.md).

| Option                             | Description                                                                                                                                                                       |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--hook`                           | Read the edited files from an AI agent hook payload on stdin instead of the arguments.                                                                                            |
| `-p`, `--prevent-concurrent-write` | Wait 2 seconds, clean a copy of the file, then overwrite the original only if it hasn't changed meanwhile. For editor on-save hooks, where the IDE may still be writing the file. |
| `-h`, `--help`                     | Print usage and exit.                                                                                                                                                             |

To format on save in VS Code or Cursor, install the [immosquare-vscode](https://marketplace.visualstudio.com/items?itemName=immosquare.immosquare-vscode) extension.

## 💎 In a Ruby or Rails project

immosquare-cleaner started as the formatter of immosquare's Rails apps and still covers the whole Ruby ecosystem: RuboCop with custom cops, ERB templates through htmlbeautifier and erb_lint, Rails translation files, a Gemfile setup and a Ruby API. All of it is on one page: [ruby-erb.md](docs/ruby-erb.md).

## 📚 Documentation

The README covers installation and the agent hook; the `docs/` folder goes deeper, one page per topic:

| Page                                      | Content                                                                                   |
| ----------------------------------------- | ----------------------------------------------------------------------------------------- |
| [agent-hooks.md](docs/agent-hooks.md)     | How `--hook` finds the edited files for each agent, its guarantees, troubleshooting       |
| [repository.md](docs/repository.md)       | Cleaning a whole repository: file selection, exclusions, threads                          |
| [javascript.md](docs/javascript.md)       | ESLint rules fixed and reported, comment normalization, known limits                      |
| [rust-toml.md](docs/rust-toml.md)         | rustfmt edition and configuration lookup, taplo options                                   |
| [go.md](docs/go.md)                       | `gofmt -s`, why Go keeps tabs, Go files left alone                                        |
| [shell.md](docs/shell.md)                 | Shell files matched, shfmt options                                                        |
| [markdown.md](docs/markdown.md)           | The four rules of the built-in Markdown formatter                                         |
| [other-formats.md](docs/other-formats.md) | Prettier configuration for CSS, YAML, Vue, GraphQL; JSON layout; unknown files            |
| [ruby-erb.md](docs/ruby-erb.md)           | RuboCop style and custom cops, ERB linters, Rails locales, configuration file, Gemfile    |

## 🤝 Contributing and license

Bug reports and pull requests are welcome on [GitHub](https://github.com/immosquare/immosquare-cleaner). See [CONTRIBUTING.md](CONTRIBUTING.md) to set up the repository and run the test suite.

immosquare-cleaner is available as open source under the terms of the [MIT License](LICENSE).
