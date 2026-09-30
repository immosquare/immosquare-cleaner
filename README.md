---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# immosquare-cleaner

immosquare-cleaner is a meticulously crafted Ruby gem to enhance the cleanliness and structure of your project's files. This tool ensures consistency and uniformity across various formats, including Ruby, ERB, YAML, Markdown, JSON, JS, Rust, TOML, CSS, SASS, LESS, and other formats supported by Prettier.

This README is written for developers working on a project that uses immosquare-cleaner (a Rails app, a gem, a Rust/Tauri app…), and for developers working on the gem itself. It covers the formats immosquare-cleaner supports and the tool each one is delegated to, the linter configurations and the custom cops and linters the gem ships, how to install immosquare-cleaner and run it on a single file or on a whole repository, and how to run the gem's own test suite. immosquare-cleaner requires [bun](https://bun.sh/) and [shfmt](https://github.com/mvdan/sh); Rust and TOML files additionally need [rustfmt](https://github.com/rust-lang/rustfmt) and [taplo](https://taplo.tamasfe.dev/).

## Supported formats and the tool each one is delegated to

immosquare-cleaner recognizes and caters to various file formats, and hands each file to the processor that owns its format. The table below lists every supported file type, the extensions or file names that select it, and the external tool or in-house module that does the formatting.

| File Type   | File Extension                                                                                                                                                                                                                                          | Processor                                                                                                           |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ERB         | `.html.erb` , `.html`                                                                                                                                                                                                                                   | [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier) && [erb-lint](https://github.com/Shopify/erb-lint) |
| Ruby        | `.rb`, `.rake`, `Gemfile`, `Rakefile`, `Brewfile`, `.axlsx`, `.cap`, `.gemspec`, `.ru`, `.podspec`, `.jbuilder`, `.rabl`, `.thor`, `Berksfile`, `Capfile`, `Guardfile`, `Podfile`, `Thorfile`, `Vagrantfile`, files starting with `#!/usr/bin/env ruby` | [rubocop](https://rubocop.org/)                                                                                     |
| YAML        | `.yml` (only files in locales folder)                                                                                                                                                                                                                   | [ImmosquareYaml](https://github.com/immosquare/immosquare-yaml)                                                     |
| JS          | `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.js.erb`, `.mjs.erb`, `.cjs.erb`, `.jsx.erb`, `.ts.erb`, `.tsx.erb`, `.coffee.erb`                                                                                                                       | [eslint](https://eslint.org/)                                                                                       |
| JSON        | `.json`                                                                                                                                                                                                                                                 | [ImmosquareExtensions](https://github.com/immosquare/immosquare-extensions)                                         |
| Markdown    | `.md`, `.md.erb`                                                                                                                                                                                                                                        | [ImmosquareCleaner](https://github.com/immosquare/immosquare-cleaner)                                               |
| Shell       | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                                                                                                                                                                                     | [shfmt](https://github.com/mvdan/sh)                                                                                |
| Rust        | `.rs`                                                                                                                                                                                                                                                   | [rustfmt](https://github.com/rust-lang/rustfmt)                                                                     |
| TOML        | `.toml`                                                                                                                                                                                                                                                 | [taplo](https://taplo.tamasfe.dev/)                                                                                 |
| Others      | Any other format                                                                                                                                                                                                                                        | [prettier](https://prettier.io/)                                                                                    |

When rustfmt, taplo or shfmt is missing, immosquare-cleaner prints the install command (`rustup component add rustfmt`, `brew install taplo`, `brew install shfmt`) and leaves the file untouched.

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

## Linter configurations, custom RuboCop cops and custom erb_lint linters

You can view the specific configurations for all supported linters in the [linters folder](https://github.com/immosquare/immosquare-cleaner/tree/main/linters) of the repository.

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

## Installing immosquare-cleaner and running it on a file or a whole repository

immosquare-cleaner requires [bun](https://bun.sh/) and [shfmt](https://github.com/mvdan/sh) (`brew install shfmt`). In a Ruby project, add the gem to the development group of your `Gemfile`:

```ruby
gem "immosquare-cleaner", :group => :development
```

In a project without a `Gemfile` (a Rust or JS repository), install the gem globally and call `immosquare-cleaner` without `bundle exec`:

```bash
gem install immosquare-cleaner
```

The config file is optional. If you want to use it, it must be placed in the `config/initializers` folder and must be named `immosquare-cleaner.rb`:

```ruby
ImmosquareCleaner.config do |config|
  config.rubocop_options        = "--your-rubocop-options-here"
  config.htmlbeautifier_options = "--your-htmlbeautifier-options-here"
  config.erblint_options        = "--your-erblint-options-here"
  config.exclude_files          = ["db/schema.rb", "db/seeds.rb", "..."]
end
```

On the command line, immosquare-cleaner cleans the file it is given:

```bash
bundle exec immosquare-cleaner path/to/your/file.rb
```

The command-line options of the `immosquare-cleaner` executable:

| Option                             | Description                                                                                                                                                                                                                                                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-p`, `--prevent-concurrent-write` | Wait 2 seconds, clean a copy of the file in `/tmp`, then overwrite the original only if it hasn't changed in the meantime. Use when an IDE may be saving the file in parallel (e.g. editor on-save hook). The project configuration (`Cargo.toml`, `rustfmt.toml`) is still read from the original location. Single files only. |
| `-h`, `--help`                     | Print usage and exit.                                                                                                                                                                                                                                                                                                           |

On first run, the CLI runs `bun install` automatically if the gem's `node_modules/` is missing.

The same single-file cleaning is available from Ruby:

```ruby
ImmosquareCleaner.clean("path/to/your/file.rb")
```

### Cleaning a whole repository in one run

Given a directory instead of a file, immosquare-cleaner cleans every source file of the repository in one run (onboarding, cleaner upgrade, large refactor), whatever its stack: Rails app, gem, Rust/Tauri app, JS package. Run it from the repository root:

```bash
bundle exec immosquare-cleaner .
```

The directory clean selects its files as follows:

| Step               | Behaviour                                                                                                                                                                                                                                                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Listing            | Files come from `git ls-files` (tracked and untracked, minus `.gitignore`), so each stack's build output is skipped by the repository's own rules. A nested repository or a submodule is walked with its own listing, so a folder holding several repositories cleans all of them. Outside a git repository, every file under the directory is listed. |
| Excluded folders   | `.git`, `build`, `coverage`, `dist`, `log`, `node_modules`, `target`, `tmp` and `vendor` at any depth; `app/assets/builds`, `app/assets/fonts`, `app/assets/images`, `db`, `public`, `src-tauri/gen`, `src-tauri/permissions/autogenerated` and `test` from the root of each repository.                                                               |
| Excluded files     | `package-lock.json`, `pnpm-lock.yaml`, `npm-shrinkwrap.json`, `*.min.js`, `*.min.css`, symlinks, and the `exclude_files` of the project's `config/initializers/immosquare-cleaner.rb`.                                                                                                                                                                 |
| Supported formats  | Only files with a dedicated processor, or an extension Prettier formats out of the box (`.css`, `.scss`, `.less`, `.yml`, `.yaml`, `.vue`, `.graphql`, `.gql`, `.hbs`, `.handlebars`), are cleaned. `LICENSE`, `.env`, images and other unknown files are left alone.                                                                                  |

The run is parallelized via threads (defaults to `min(nprocessors, 8)` since linters shell out and release the GVL). Override with:

```bash
CLEANER_THREADS=4 bundle exec immosquare-cleaner .
```

The same directory clean is available from Ruby:

```ruby
ImmosquareCleaner.clean_directory("path/to/your/repository")
```

The directory clean replaces the `rake immosquare_cleaner:clean_app` task, which was limited to Rails apps and no longer exists.

To run immosquare-cleaner from Visual Studio Code or Cursor, simply install the [immosquare-vscode](https://marketplace.visualstudio.com/items?itemName=immosquare.immosquare-vscode) extension from the VS Code marketplace. That's it!

## Why immosquare-cleaner pins TypeScript to the 6.0.3 tarball

TypeScript 7 is installed as `@typescript/native`, but TypeScript 7.0 does not expose the stable programmatic API required by `typescript-eslint` and SonarJS. The `typescript` dependency therefore resolves to the fixed 6.0.3 npm tarball; using the tarball prevents `bun update --latest` from replacing the linter API. Remove this compatibility lock when `typescript-eslint` supports the TypeScript 7.1 API.

## Running the immosquare-cleaner test suite and its CI

The test suite of the immosquare-cleaner repository runs through rake:

```bash
bundle exec rake test
```

Coverage is off by default, so a local run stays fast and leaves no `coverage/` directory behind. Set `COVERAGE=true` to get an HTML report plus `coverage/lcov.info`:

```bash
COVERAGE=true bundle exec rake test
```

The CI runs the suite on every build through `bin/ci`, which is a repository script and is not shipped with the gem:

```bash
bin/ci init   # bundle install && bun install --frozen-lockfile
bin/ci test   # bundle exec rake test
bin/ci        # both, in that order (the default, `all`)
```

`bin/ci init` installs the JS toolchain too: the JS, Prettier and Markdown tests call the library directly rather than the `immosquare-cleaner` executable, so nothing provisions `node_modules/` for them. Both sub-commands skip the `development` bundler group — anything the suite needs belongs to the `test` group of the `Gemfile`. The script provisions no Ruby of its own — the CI runner selects it from `.ruby-version` and `.ruby-gemset` beforehand — so `bin/ci` behaves the same on a laptop. It also defaults `COVERAGE` to `true`, and the CI collects `coverage/lcov.info`.

## Contributing to immosquare-cleaner and license

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/immosquare/immosquare-cleaner).

immosquare-cleaner is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
