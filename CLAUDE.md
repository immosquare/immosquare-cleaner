# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`immosquare-cleaner` is a Ruby gem providing comprehensive code formatting and linting for Rails applications. It dispatches to different processors based on file extensions:

- **Ruby files** (`.rb`, `.rake`, Gemfiles, etc.): RuboCop
- **ERB files** (`.html.erb`, `.html`): htmlbeautifier + erb_lint
- **JavaScript/TypeScript** (`.js`, `.mjs`, `.jsx`, `.ts`, `.tsx`, `.js.erb`): ESLint + custom comment normalizer
- **JSON files**: ImmosquareExtensions JSON beautifier
- **YAML files** (in locales folders): ImmosquareYaml
- **Markdown files** (`.md`, `.md.erb`): Custom markdown processor
- **Shell files** (`.sh`, `bash`, `zsh`, etc.): shfmt
- **Other formats**: Prettier

## Development Commands

```bash
# Run tests
bundle exec rake test

# Run a single test file
bundle exec ruby -Itest test/normalize_comments_js_test.rb

# Clean a specific file
bundle exec immosquare-cleaner path/to/file.rb

# Update all dependencies
bundle update && bundle clean --force && bun update
```

## Key Architecture

### Entry Point
`lib/immosquare-cleaner.rb` - The `ImmosquareCleaner.clean(file_path)` method determines file type and dispatches to appropriate processor.

### Custom Linters

**RuboCop Cops** (`linters/rubocop/cop/custom_cops/style/`):
- `CommentNormalization`: Normalizes Ruby comment formatting with border lines
- `FontAwesomeNormalization`: Converts `fas`/`far` to `fa-solid`/`fa-regular`
- `AlignAssignments`: Aligns consecutive variable assignments (disabled by default)

**erb_lint Linters** (`linters/erb_lint/`):
- `CustomSingleLineIfModifier`: `<% if cond %><%= x %><% end %>` → `<%= x if cond %>`
- `CustomHtmlToContentTag`: `<div class="x"><%= y %></div>` → `<%= content_tag(:div, y, :class => "x") %>`

**JS Comment Normalizer** (`linters/normalize-comments.mjs`):
- Adds border lines (`//====...====//`) around standalone comments
- Preserves sprockets directives (`//= require`), TypeScript triple-slash, and end-of-line comments

### Critical Implementation Details

1. **erb_lint Symlink**: `.erb_linters -> linters/erb_lint` is required because erb_lint hardcodes the custom linters directory path.

2. **ESLint V9+ Workaround**: Due to "File ignored because outside of base path" issue, JS files are copied to `tmp/` within the gem directory before linting, then copied back.

3. **Version-Specific Configs**: The gem generates `rubocop-{VERSION}.yml` and `erb-lint-{VERSION}.yml` on first run. Delete these when modifying base configs to force regeneration.

4. **Parser Selection**: Uses `parser_prism` for Ruby 3.3+, `parser_whitequark` for older versions.

5. **Command Execution**: All linter commands run from the gem root via `Dir.chdir(gem_root)` to ensure correct path resolution.

## Prerequisites

- **Bun**: Required for ESLint, Prettier, and the JS comment normalizer
- **Ruby 3.2.6+**: Minimum Ruby version
- **shfmt**: Required for shell script formatting (`brew install shfmt`)