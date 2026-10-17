# CLAUDE.md

Multi-format formatting/linting gem for any repository (Rails app, Ruby gem, Rust/Tauri app, Go module, JS package). Entry points: `ImmosquareCleaner.clean(file_path)` and `ImmosquareCleaner.clean_directory(root)` in `lib/immosquare-cleaner.rb`.

This is a public gem. Use English for project documentation, source comments, and project communication.

## Architecture

One processor per file type in `lib/immosquare-cleaner/processors/`; each class exposes `match?(file_path)` and `run`. `ImmosquareCleaner.processor_for` scans the `PROCESSORS` registry (order matters: `Erb` before `Javascript`, `Ruby` before `Shell` for shebangs) and falls back to `Processors::Prettier`.

`ImmosquareCleaner.clean_directory(root)` (`lib/immosquare-cleaner/directory_cleaner.rb`) cleans an entire repository regardless of its stack: files come from `git ls-files` (nested repositories and submodules use their own listings; `Dir.glob` is used outside Git), hardcoded exclusions apply (`EXCLUDED_DIRS` at any depth, `EXCLUDED_PATHS` relative to each repository root), and only files handled by a processor or whose extension Prettier supports are processed (`Prettier::EXTENSIONS`, through `ImmosquareCleaner.supported?`).

| Processor                | Extension                                                                             | Tool                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `Processors::Ruby`       | `.rb`, `.rake`, Gemfile and others (see `RUBY_FILES`) + shebang `#!/usr/bin/env ruby` | RuboCop                                                                                   |
| `Processors::Erb`        | `.html.erb`, `.html`                                                                  | htmlbeautifier + erb_lint                                                                 |
| `Processors::Yaml`       | `.yml` in `locales/`                                                                  | ImmosquareYaml                                                                            |
| `Processors::Javascript` | `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.{js,mjs,cjs,jsx,ts,tsx,coffee}.erb`   | ESLint + normalize-comments.mjs (or erb_lint for `.erb` files)                            |
| `Processors::Json`       | `.json`                                                                               | ImmosquareExtensions                                                                      |
| `Processors::Markdown`   | `.md`, `.md.erb`                                                                      | `ImmosquareCleaner::Markdown.clean` (tables + lists; YAML frontmatter preserved verbatim) |
| `Processors::Shell`      | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                   | shfmt                                                                                     |
| `Processors::Rust`       | `.rs`                                                                                 | rustfmt via stdin (edition and `rustfmt.toml` read from the project)                      |
| `Processors::Go`         | `.go`                                                                                 | `gofmt -s` (tab indentation: gofmt has no indentation option)                             |
| `Processors::Toml`       | `.toml`                                                                               | taplo                                                                                     |
| `Processors::Prettier`   | Fallback (all remaining supported formats)                                            | Prettier                                                                                  |

## Commands

```bash
bundle exec rake test                              # Tests
bundle exec ruby -Itest test/xxx_test.rb            # Single test
bundle exec immosquare-cleaner path/to/file         # Clean a file
bundle exec immosquare-cleaner path/to/repo         # Entire repository, any stack (parallel; override with CLEANER_THREADS=N)
COVERAGE=true bundle exec rake test                # Tests + HTML report and coverage/lcov.info
bin/ci                                            # CI entry point (bundle + bun install, then the suite)
```

## Custom Linters

**RuboCop** (`linters/rubocop/cop/custom_cops/style/`):

- `CommentNormalization`: Adds borders around comments.
- `FontAwesomeNormalization`: Converts `fas`/`far` to `fa-solid`/`fa-regular`.
- `AlignAssignments`: Aligns consecutive `=` operators (disabled by default).
- `InlineMultilineCalls`: Collapses multiline `link_to(...)` calls to a single line (skips calls containing multiline comments or strings).
- `KwargPriorityOrder`: Reorders `link_to` keyword arguments to put `:remote` first, followed by `:method` (configurable).

**RuboCop** (`linters/rubocop/cop/style/`):

- `MethodCallWithArgsParentheses` override: Allows omitted parentheses in Jbuilder blocks/files (`json.field "value"`).

**erb_lint** (`linters/erb_lint/`):

- `CustomSingleLineIfModifier`: Converts `<% if x %><%= y %><% end %>` to `<%= y if x %>`.
- `CustomHtmlToContentTag`: Converts `<div class="x"><%= y %></div>` to `<%= content_tag(:div, y, :class => "x") %>`.
- `CustomAlignConsecutiveCalls`: Aligns columns in consecutive `link_to` calls (same arity and keyword argument keys) using padding after commas.

**JS** (`linters/normalize-comments.mjs`):

- Adds `//====...====//` borders around standalone comments.

**ESLint 10 compatibility shim** (`linters/eslint-plugins/eslint10-compat.mjs`):

- Wraps `eslint-plugin-align-import` (unmaintained; last release in 2020) to restore `context.getSourceCode()`, removed in ESLint 10. Remove the shim once a maintained alternative is available.
- `align-assignments` is a local fork (`linters/eslint-plugins/align-assignments.mjs`, MIT, original notice at the top of the file): it reads `context.sourceCode` and handles `||=`, `&&=`, and `??=`. Without support for these operators, autofix never converges ("Circular fixes detected").

## Critical Details

- **erb_lint symlink**: `.erb_linters -> linters/erb_lint` is required (the path is hardcoded by erb_lint).
- **ESLint 10**: Files are copied into `tmp/` before linting, then copied back (workaround for "outside of base path"; see `eslint/eslint#19118`). Legacy plugins are adapted through the `eslint10-compat.mjs` shim.
- **TypeScript 7**: Keep the native compiler and the lint compatibility API separate; see [TypeScript 7 compatibility](#typescript-7-compatibility) before changing either dependency.
- **Generated linter configs**: `rubocop-{TARGET}-{FINGERPRINT}.yml`, `erb-lint-…` and `js-erb-lint-…` are generated on demand in `linters/` (`ImmosquareCleaner.linter_config_path`). `{FINGERPRINT}` hashes the three templates, so editing a template regenerates them; writes are atomic under a mutex for parallel cleaning. They are gitignored and excluded from `spec.files`.
- **Ruby target**: `RubyTarget.detect` (`lib/immosquare-cleaner/ruby_target.rb`) takes the gemspec `required_ruby_version` minimum, then `.ruby-version`, then `RUBY_VERSION`, stopping at the project root (`*.gemspec`, `Gemfile` or `.git`); `ruby_target_version` in the configuration overrides it. Processors pass `origin_path`, never the `/tmp` copy.
- **Ruby parser**: `parser_prism` (target 3.3+) or `parser_whitequark` (earlier targets).
- **Execution**: Commands run from the gem root through `system(cmd, :chdir => gem_root)` (thread-safe; no `Dir.chdir`).
- **`bin/ci` is not packaged**: The gemspec lists `bin/` files individually (`bin/immosquare-cleaner` only). `bin/ci` is the CI entry point and does not belong in an installed gem.
- **Coverage**: `test/coverage_helper.rb` is loaded through the Rakefile's `ruby_opts`, before the library; otherwise, files already required escape coverage measurement. It does nothing unless `COVERAGE=true`.
- **`--hook` CLI**: `bin/immosquare-cleaner --hook` reads edited file paths from the JSON an AI agent sends on stdin (`ImmosquareCleaner::Hook.file_paths`, `lib/immosquare-cleaner/hook.rb`: `tool_input.file_path`, `tool_input.path`, `toolInput.file_path`, top-level `file_path`, or, for Codex, the patch lines `*** Update File:` / `Add File:` / `Move to:` in `tool_input.command`, resolved relative to `tool_input.workdir`, then `cwd`). Missing files, symlinks, or files that are not `supported?` are ignored, with exit status 0 and no action. Stdout is redirected to stderr because Codex and Gemini CLI parse hook stdout as JSON. Never return a nonzero exit status in this mode: it would block the agent.
- **`-p` CLI**: `bin/immosquare-cleaner -p` cleans a copy in `/tmp` after a 2-second delay and writes back only if the original has not changed, so it can coexist with an IDE saving concurrently. The original path is passed as `origin_path` (`Processors::Base`); processors that read project configuration (`Cargo.toml`, `rustfmt.toml`) look it up from the original path rather than `/tmp`.
- **Markdown tables**: `Markdown.table_cells` splits a line on unescaped `|` characters. An escaped `\|` is cell content (GFM); using `split("|")` would add a column to the entire table.
- **`.jsx` in ESLint**: The flat config only lints `.js`/`.mjs`/`.cjs` by default. The `files: ["**/*.jsx"]` block in `linters/eslint.config.mjs` is required; otherwise, ESLint silently ignores the file ("no matching configuration").
- **README GIF**: `assets/demo.gif` is generated with `vhs assets/demo.tape` (requires vhs, bat, and git-delta). `assets/` is not packaged in the gem.
- **rustfmt via stdin**: When given a file path, rustfmt also rewrites child modules (`mod foo;`); `skip_children` is only available on nightly.

## TypeScript 7 compatibility

Last reviewed: **2026-10-12**. The latest stable compiler is TypeScript **7.0.2**. `@typescript-eslint/parser` and `@typescript-eslint/eslint-plugin` **8.71.2** require TypeScript `>=4.8.4 <6.1.0`; `eslint-plugin-sonarjs` **4.2.2** depends on TypeScript `>=5 <6.1.0`.

TypeScript 7.0 is a native compiler written in Go and does not expose the JavaScript compiler API that these lint tools require. Installing it directly as `typescript` makes the ESLint configuration fail to load, including when formatting plain JavaScript. This is an upstream API compatibility blocker.

Keep Microsoft's official side-by-side setup in `package.json`:

- `@typescript/native: "npm:typescript@^7.0.2"` provides the TypeScript 7 `tsc` executable.
- `typescript: "npm:@typescript/typescript6@^6.0.2"` provides the TypeScript 6 API for ESLint and SonarJS, plus the separate `tsc6` executable. The compatibility package version is 6.0.2; its underlying compiler API currently resolves to 6.0.3.

The immosquare dependency updater (`app/services/dependencies/js_updater.rb` in immosquare (app)) runs `bun update <package> --latest --lockfile-only --ignore-scripts`, then a global update. A tarball URL is not an update guard: Bun can replace it with the latest `typescript` release. The official npm alias makes Bun follow `@typescript/typescript6` instead. With Bun 1.4.3, the complete updater pass and its major-version lookup preserve both aliases and the lockfile. Do not replace this compatibility alias with a tarball URL or a direct TypeScript 7 dependency while the API blocker remains.

### Periodic compatibility review

When working on JS/TS dependencies or investigating lint/CI failures, recheck this blocker if the last review is at least one week old. Check the npm stable releases and official release notes for TypeScript, both `@typescript-eslint` packages above, and SonarJS. Update the review date and version findings in this section.

Microsoft expects a new native API in TypeScript 7.1; the release of 7.1 alone is not sufficient to remove TypeScript 6. Remove the compatibility setup only once the stable native API is available and both typescript-eslint and SonarJS explicitly support it. Before changing the dependency setup, verify a clean `bun install --frozen-lockfile`, JS/JSX/TS/TSX lint and autofix, and a complete dependency-updater pass in a disposable workspace. Regenerate `bun.lock` with Bun rather than editing it by hand.

Official references: [Microsoft's side-by-side installation guidance](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/#running-side-by-side-with-typescript-6-0), [typescript-eslint dependency support](https://typescript-eslint.io/users/dependency-versions/), and [SonarJS releases](https://github.com/SonarSource/SonarJS/releases).

## Requirements

Bun, Ruby 3.2.6+, and shfmt (`brew install shfmt`); rustfmt (`rustup component add rustfmt`), gofmt (`brew install go`), and taplo (`brew install taplo`) for Rust, Go, and TOML files.
