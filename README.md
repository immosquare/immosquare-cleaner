---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# immosquare-cleaner

**One command that formats every file of your repository — Ruby, ERB, JS/TS, Rust, Go, TOML, Markdown, Shell, JSON, YAML, CSS — with one consistent house style. Wire it into your AI coding agent and every file the agent writes comes out formatted.**

[![Gem Version](https://img.shields.io/gem/v/immosquare-cleaner)](https://rubygems.org/gems/immosquare-cleaner) [![Downloads](https://img.shields.io/gem/dt/immosquare-cleaner)](https://rubygems.org/gems/immosquare-cleaner) [![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

AI agents write code fast, but not in your style: single quotes in one file, semicolons in the next, a `return` nobody needs. immosquare-cleaner picks the right tool for each file (RuboCop, erb_lint, ESLint, rustfmt, gofmt, taplo, shfmt, Prettier, plus in-house formatters for Markdown, JSON and YAML locales), runs it with a shared configuration, and writes the result back. Run it on one file, on a whole repository, from your editor on save, or from an agent hook after every edit.

- **One entry point for every format**: no per-language formatter to install and configure in each project.
- **Built for agent hooks**: `immosquare-cleaner --hook` reads the edit payload of Claude Code, Cursor, Gemini CLI and others on stdin, never blocks the agent, and skips files it does not handle.
- **Any stack**: Rails apps, gems, Rust/Tauri apps, Go modules, JS packages. A whole repository is cleaned in parallel, using `git ls-files` so `.gitignore` is honored.
- **Opinionated on purpose**: the configuration is the immosquare house style (see [The house style](#the-house-style-linter-configurations-and-custom-linters)). You get consistency without writing a single config file.

## Quick start

immosquare-cleaner needs Ruby 3.2.6+ and [bun](https://bun.sh/), which runs ESLint and Prettier; their packages are installed automatically on first run.

```bash
gem install immosquare-cleaner
immosquare-cleaner app/models/user.rb   # one file
immosquare-cleaner .                    # the whole repository
```

In a Ruby project, add it to the development group of your `Gemfile` instead, and prefix the commands with `bundle exec`:

```ruby
gem "immosquare-cleaner", :group => :development
```

## Before and after

A Ruby file as an agent might write it:

```ruby
class User < ApplicationRecord
  # Full name shown in the header
  def display_name
    name = [first_name, last_name].compact.join(' ')
    options = {title: name, class: 'user'}
    return name
  end
end
```

After `immosquare-cleaner user.rb`:

```ruby
class User < ApplicationRecord

  # Full name shown in the header
  def display_name
    name = [first_name, last_name].compact.join(" ")
    options = {:title => name, :class => "user"}
    name
  end

end
```

A JavaScript file:

```js
import {fetchJson} from "./http"
import {formatName} from "./format"
// Load the user and build its label
export const userLabel = async (id) => {
  let user = await fetchJson('/users/' + id);
  let label = formatName(user);
  return label;
}
```

After `immosquare-cleaner app.js`:

```js
import {fetchJson}  from "./http"
import {formatName} from "./format"
//============================================================//
// Load the user and build its label
//============================================================//
export const userLabel = async (id) => {
  let user = await fetchJson("/users/" + id)
  return formatName(user)
}
```

## Using immosquare-cleaner as an AI agent hook

An agent hook runs a command after each file edit. With `--hook`, immosquare-cleaner reads the agent's JSON payload on stdin, finds the edited file and cleans it. Its behaviour is the same for every agent:

| Situation                                                             | Behaviour                                                                                   |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| The edited file has a processor or a Prettier-supported extension     | The file is cleaned in place                                                                |
| No path in the payload, deleted file, directory, `LICENSE`, `.env`... | Nothing happens                                                                             |
| Invalid or empty payload                                              | Nothing happens                                                                             |
| Linter reports                                                        | Written to stderr, never to stdout, which some agents (Gemini CLI) parse as the hook answer |
| Exit status                                                           | Always `0`: the hook never blocks the agent                                                 |

The edited path is read from `tool_input.file_path` (Claude Code, Gemini CLI), `tool_input.path` (Kimi Code), `toolInput.file_path` (Grok) or a top-level `file_path` (Cursor). A relative path is resolved against the payload's `cwd`.

**Claude Code** — in `.claude/settings.json` (project) or `~/.claude/settings.json` (every project):

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

**Cursor** — in `.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [{"command": "immosquare-cleaner --hook"}]
  }
}
```

**Gemini CLI** — in `.gemini/settings.json`:

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

Agents run hooks in a non-interactive shell, where version managers such as rvm, rbenv or asdf may not be initialized. If the hook cannot find the executable, use its absolute path (`which immosquare-cleaner`), or `bundle exec immosquare-cleaner --hook` when the gem is in the project's `Gemfile`.

## Supported formats and the tool each one is delegated to

immosquare-cleaner hands each file to the processor that owns its format. The table below lists every supported file type, the extensions or file names that select it, and the external tool or in-house module that does the formatting.

| File Type | File Extension                                                                                                                                                                                                                                          | Processor                                                                                                           |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ERB       | `.html.erb` , `.html`                                                                                                                                                                                                                                   | [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier) && [erb-lint](https://github.com/Shopify/erb-lint) |
| Ruby      | `.rb`, `.rake`, `Gemfile`, `Rakefile`, `Brewfile`, `.axlsx`, `.cap`, `.gemspec`, `.ru`, `.podspec`, `.jbuilder`, `.rabl`, `.thor`, `Berksfile`, `Capfile`, `Guardfile`, `Podfile`, `Thorfile`, `Vagrantfile`, files starting with `#!/usr/bin/env ruby` | [rubocop](https://rubocop.org/)                                                                                     |
| YAML      | `.yml` (only files in locales folder)                                                                                                                                                                                                                   | [ImmosquareYaml](https://github.com/immosquare/immosquare-yaml)                                                     |
| JS        | `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.js.erb`, `.mjs.erb`, `.cjs.erb`, `.jsx.erb`, `.ts.erb`, `.tsx.erb`, `.coffee.erb`                                                                                                                       | [eslint](https://eslint.org/)                                                                                       |
| JSON      | `.json`                                                                                                                                                                                                                                                 | [ImmosquareExtensions](https://github.com/immosquare/immosquare-extensions)                                         |
| Markdown  | `.md`, `.md.erb`                                                                                                                                                                                                                                        | [ImmosquareCleaner](https://github.com/immosquare/immosquare-cleaner)                                               |
| Shell     | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                                                                                                                                                                                     | [shfmt](https://github.com/mvdan/sh)                                                                                |
| Rust      | `.rs`                                                                                                                                                                                                                                                   | [rustfmt](https://github.com/rust-lang/rustfmt)                                                                     |
| Go        | `.go`                                                                                                                                                                                                                                                   | [gofmt](https://pkg.go.dev/cmd/gofmt)                                                                               |
| TOML      | `.toml`                                                                                                                                                                                                                                                 | [taplo](https://taplo.tamasfe.dev/)                                                                                 |
| Others    | Any other format                                                                                                                                                                                                                                        | [prettier](https://prettier.io/)                                                                                    |

shfmt, rustfmt, gofmt and taplo are only needed for their own formats. When one is missing, immosquare-cleaner prints the install command (`brew install shfmt`, `rustup component add rustfmt`, `brew install go`, `brew install taplo`) and leaves the file untouched.

Go files are run through `gofmt -s`, which also applies gofmt's simplifications (`[]T{T{1}}` → `[]T{{1}}`, `s[a:len(s)]` → `s[a:]`). Unlike the other formats, Go files keep gofmt's tab indentation: gofmt has no option for it, and any other indent would make gopls and `gofmt -l` checks flag the file as unformatted. `go.mod`, `go.work` and `go.sum` are not formatted.

### Rust and TOML formatting follow the edited project's configuration

rustfmt and taplo are run with settings that depend on the project the file belongs to, not only on the gem's own configuration:

| Tool    | Behaviour                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| rustfmt | The file is piped through stdin, so rustfmt never rewrites the child modules a `mod foo;` declaration points to. The edition is read from the closest `Cargo.toml` that declares one, walking up to the workspace root for members using `edition.workspace = true`; `2024` when none does. The closest `rustfmt.toml` / `.rustfmt.toml` wins, then the user's global rustfmt config; with none, immosquare-cleaner applies a 2-space indent. On a syntax error, rustfmt's message is printed and the file is left untouched. |
| taplo   | The `=` of consecutive keys are aligned, nested arrays are indented with 2 spaces, lines are never wrapped, and multi-line arrays (workspace `members`, `features`) keep their layout. A `.taplo.toml` in the project is not read.                                                                                                                                                                                                                                                                                            |

### Markdown formatting rules applied by ImmosquareCleaner::Markdown

Markdown is the only format handled in-house instead of being delegated to an external tool. `ImmosquareCleaner::Markdown.clean` rewrites a file according to four rules, and strips trailing whitespace on every line. Each row below names the construct the rule applies to and the behaviour immosquare-cleaner guarantees for it.

| Rule               | Behaviour                                                                                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Tables             | Every cell is padded to the width of its column and separator rows are filled with dashes. An empty cell keeps its column rather than being dropped, which would file the following values under the wrong header. |
| Lists              | A blank line is inserted after the last item of a list. A marker (`*`, `+`, `-`) only opens a list when a space follows it, so a `---` thematic break or a line opening on `*emphasis*` is left alone.             |
| Fenced code blocks | Emitted verbatim. A block only closes on a fence using the marker it opened with, so a fence of the other kind shown inside it does not end it early.                                                              |
| YAML frontmatter   | Emitted verbatim: a `---` first line followed by a matching closing `---` is YAML, not markdown. Only its leading blank lines are dropped, since they are never meaningful there.                                  |

## The house style: linter configurations and custom linters

immosquare-cleaner applies the immosquare house style: hash rockets (`:key => value`) and double quotes in Ruby, no semicolons in JS, aligned imports, comments framed by `##====##` / `//====//` borders, 2-space indentation wherever the tool allows it. You can view the configuration of every linter in the [linters folder](https://github.com/immosquare/immosquare-cleaner/tree/main/linters) of the repository, and override the RuboCop, htmlbeautifier and erb_lint options per project (see [Configuration](#configuration)).

On top of those configurations, immosquare-cleaner ships custom RuboCop cops. Each row below gives the cop's fully qualified name and what it normalizes in Ruby code.

| Cop                                         | Description                                                          |
| ------------------------------------------- | -------------------------------------------------------------------- |
| `CustomCops/Style/CommentNormalization`     | Normalizes comment formatting                                        |
| `CustomCops/Style/FontAwesomeNormalization` | Standardizes Font Awesome class names (fas -> fa-solid)              |
| `CustomCops/Style/AlignAssignments`         | Aligns consecutive variable assignments (disabled by default)        |
| `CustomCops/Style/InlineMultilineCalls`     | Collapses multi-line calls (default: `link_to`) onto a single line   |
| `CustomCops/Style/KwargPriorityOrder`       | Reorders kwargs of `link_to` so `:remote`/`:method` come first       |
| `Style/MethodCallWithArgsParentheses`       | Allows parentheses omission in Jbuilder blocks and `.jbuilder` files |

immosquare-cleaner also ships custom erb_lint linters for ERB files. Each row below gives the linter's name and the ERB rewrite or alignment it performs.

| Linter                        | Description                                                                              |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| `CustomSingleLineIfModifier`  | Converts `<% if cond %><%= x %><% end %>` to `<%= x if cond %>`                          |
| `CustomHtmlToContentTag`      | Converts `<div class="x"><%= y %></div>` to `<%= content_tag(:div, y, :class => "x") %>` |
| `CustomAlignConsecutiveCalls` | Aligns args of consecutive ERB calls (default: `link_to`) when keys/arity match          |

## Command line, configuration and Ruby API

The command-line options of the `immosquare-cleaner` executable:

| Option                             | Description                                                                                                                                                                                                                                                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--hook`                           | Read the edited file from an AI agent hook payload on stdin instead of the arguments (see [Using immosquare-cleaner as an AI agent hook](#using-immosquare-cleaner-as-an-ai-agent-hook)).                                                                                                                                       |
| `-p`, `--prevent-concurrent-write` | Wait 2 seconds, clean a copy of the file in `/tmp`, then overwrite the original only if it hasn't changed in the meantime. Use when an IDE may be saving the file in parallel (e.g. editor on-save hook). The project configuration (`Cargo.toml`, `rustfmt.toml`) is still read from the original location. Single files only. |
| `-h`, `--help`                     | Print usage and exit.                                                                                                                                                                                                                                                                                                           |

On first run, the CLI runs `bun install` automatically if the gem's `node_modules/` is missing.

### Configuration

The config file is optional. If you want to use it, it must be placed in the `config/initializers` folder and must be named `immosquare-cleaner.rb`:

```ruby
ImmosquareCleaner.config do |config|
  config.rubocop_options        = "--your-rubocop-options-here"
  config.htmlbeautifier_options = "--your-htmlbeautifier-options-here"
  config.erblint_options        = "--your-erblint-options-here"
  config.exclude_files          = ["db/schema.rb", "db/seeds.rb", "..."]
end
```

### Ruby API

The single-file and directory cleans are available from Ruby:

```ruby
ImmosquareCleaner.clean("path/to/your/file.rb")
ImmosquareCleaner.clean_directory("path/to/your/repository")
```

### Cleaning a whole repository in one run

Given a directory instead of a file, immosquare-cleaner cleans every source file of the repository in one run (onboarding, cleaner upgrade, large refactor), whatever its stack: Rails app, gem, Rust/Tauri app, Go module, JS package. Run it from the repository root:

```bash
bundle exec immosquare-cleaner .
```

The directory clean selects its files as follows:

| Step              | Behaviour                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Listing           | Files come from `git ls-files` (tracked and untracked, minus `.gitignore`), so each stack's build output is skipped by the repository's own rules. A nested repository or a submodule is walked with its own listing, so a folder holding several repositories cleans all of them. Outside a git repository, every file under the directory is listed.                                                                                                                                                                                                                           |
| Excluded folders  | `.git`, `build`, `coverage`, `dist`, `log`, `node_modules`, `target`, `testdata` (Go test fixtures), `tmp` and `vendor` at any depth; `app/assets/builds`, `app/assets/fonts`, `app/assets/images`, `db`, `public`, `src-tauri/gen`, `src-tauri/permissions/autogenerated` and `test` from the root of each repository; anything under a `templates` folder nested in a `generators` folder (Rails generator templates hold raw ERB behind the target file's extension, which any formatter would mangle). Generator templates are also skipped when cleaned one file at a time. |
| Excluded files    | `package-lock.json`, `pnpm-lock.yaml`, `npm-shrinkwrap.json`, `*.min.js`, `*.min.css`, symlinks, and the `exclude_files` of the project's `config/initializers/immosquare-cleaner.rb`.                                                                                                                                                                                                                                                                                                                                                                                           |
| Supported formats | Only files with a dedicated processor, or an extension Prettier formats out of the box (`.css`, `.scss`, `.less`, `.yml`, `.yaml`, `.vue`, `.graphql`, `.gql`, `.hbs`, `.handlebars`), are cleaned. `LICENSE`, `.env`, images and other unknown files are left alone.                                                                                                                                                                                                                                                                                                            |

The run is parallelized via threads (defaults to `min(nprocessors, 8)` since linters shell out and release the GVL). Override with:

```bash
CLEANER_THREADS=4 bundle exec immosquare-cleaner .
```

### Editor integration

To run immosquare-cleaner on save from Visual Studio Code or Cursor, install the [immosquare-vscode](https://marketplace.visualstudio.com/items?itemName=immosquare.immosquare-vscode) extension from the VS Code marketplace.

## Contributing and license

Bug reports and pull requests are welcome on [GitHub](https://github.com/immosquare/immosquare-cleaner). See [CONTRIBUTING.md](CONTRIBUTING.md) to run the test suite and for the maintainer notes.

immosquare-cleaner is available as open source under the terms of the [MIT License](LICENSE).
