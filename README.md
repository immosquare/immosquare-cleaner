---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# Immosquare-cleaner

A meticulously crafted Ruby gem to enhance the cleanliness and structure of your project's files. This tool ensures consistency and uniformity across various formats, including Ruby, ERB, YAML, Markdown, JSON, JS, CSS, SASS, LESS, and other formats supported by Prettier.

## Supported Formats

The cleaner recognizes and caters to various file formats:

| File Type   | File Extension                                                                                                                                                                                                                                          | Processor                                                                                                           |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ERB         | `.html.erb` , `.html`                                                                                                                                                                                                                                   | [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier) && [erb-lint](https://github.com/Shopify/erb-lint) |
| Ruby        | `.rb`, `.rake`, `Gemfile`, `Rakefile`, `Brewfile`, `.axlsx`, `.cap`, `.gemspec`, `.ru`, `.podspec`, `.jbuilder`, `.rabl`, `.thor`, `Berksfile`, `Capfile`, `Guardfile`, `Podfile`, `Thorfile`, `Vagrantfile`, files starting with `#!/usr/bin/env ruby` | [rubocop](https://rubocop.org/)                                                                                     |
| YAML        | `.yml` (only files in locales folder)                                                                                                                                                                                                                   | [ImmosquareYaml](https://github.com/immosquare/immosquare-yaml)                                                     |
| JS          | `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.js.erb`, `.mjs.erb`, `.cjs.erb`, `.jsx.erb`, `.ts.erb`, `.tsx.erb`, `.coffee.erb`                                                                                                                       | [eslint](https://eslint.org/)                                                                                       |
| JSON        | `.json`                                                                                                                                                                                                                                                 | [ImmosquareExtensions](https://github.com/immosquare/immosquare-extensions)                                         |
| Markdown    | `.md`, `.md.erb`                                                                                                                                                                                                                                        | [ImmosquareCleaner](https://github.com/immosquare/immosquare-cleaner)                                               |
| Shell       | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                                                                                                                                                                                     | [shfmt](https://github.com/mvdan/sh)                                                                                |
| Others      | Any other format                                                                                                                                                                                                                                        | [prettier](https://prettier.io/)                                                                                    |

### Markdown formatting

Markdown is the only format handled in-house instead of being delegated to an external tool. `ImmosquareCleaner::Markdown.clean` rewrites a file according to four rules, and strips trailing whitespace on every line.

| Rule               | Behaviour                                                                                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Tables             | Every cell is padded to the width of its column and separator rows are filled with dashes. An empty cell keeps its column rather than being dropped, which would file the following values under the wrong header. |
| Lists              | A blank line is inserted after the last item of a list. A marker (`*`, `+`, `-`) only opens a list when a space follows it, so a `---` thematic break or a line opening on `*emphasis*` is left alone.             |
| Fenced code blocks | Emitted verbatim. A block only closes on a fence using the marker it opened with, so a fence of the other kind shown inside it does not end it early.                                                              |
| YAML frontmatter   | Emitted verbatim: a `---` first line followed by a matching closing `---` is YAML, not markdown. Only its leading blank lines are dropped, since they are never meaningful there.                                  |

## Linter Configurations

You can view the specific configurations for all supported linters in the [linters folder](https://github.com/immosquare/immosquare-cleaner/tree/main/linters) of the repository.

### Custom RuboCop Cops

The gem includes custom RuboCop cops:

| Cop                                         | Description                                                          |
| ------------------------------------------- | -------------------------------------------------------------------- |
| `CustomCops/Style/CommentNormalization`     | Normalizes comment formatting                                        |
| `CustomCops/Style/FontAwesomeNormalization` | Standardizes Font Awesome class names (fas -> fa-solid)              |
| `CustomCops/Style/AlignAssignments`         | Aligns consecutive variable assignments (disabled by default)        |
| `CustomCops/Style/InlineMultilineCalls`     | Collapses multi-line calls (default: `link_to`) onto a single line   |
| `CustomCops/Style/KwargPriorityOrder`       | Reorders kwargs of `link_to` so `:remote`/`:method` come first       |
| `Style/MethodCallWithArgsParentheses`       | Allows parentheses omission in Jbuilder blocks and `.jbuilder` files |

### Custom erb_lint Linters

The gem includes custom erb_lint linters for ERB files:

| Linter                        | Description                                                                              |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| `CustomSingleLineIfModifier`  | Converts `<% if cond %><%= x %><% end %>` to `<%= x if cond %>`                          |
| `CustomHtmlToContentTag`      | Converts `<div class="x"><%= y %></div>` to `<%= content_tag(:div, y, :class => "x") %>` |
| `CustomAlignConsecutiveCalls` | Aligns args of consecutive ERB calls (default: `link_to`) when keys/arity match          |

## Installation

Requires [bun](https://bun.sh/) and [shfmt](https://github.com/mvdan/sh) (`brew install shfmt`).

```ruby
gem "immosquare-cleaner", :group => :development
```


### Configuration

The config file is optional. If you want to use it, it must be placed in the `config/initializers` folder and must be named `immosquare-cleaner.rb`

```ruby
ImmosquareCleaner.config do |config|
  config.rubocop_options        = "--your-rubocop-options-here"
  config.htmlbeautifier_options = "--your-htmlbeautifier-options-here"
  config.erblint_options        = "--your-erblint-options-here"
  config.exclude_files          = ["db/schema.rb", "db/seeds.rb", "..."]
end
```


## Usage

### Command Line

```bash
bundle exec immosquare-cleaner path/to/your/file.rb
```

| Option                             | Description                                                                                                                                                                                               |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-p`, `--prevent-concurrent-write` | Wait 2 seconds, clean a copy of the file in `/tmp`, then overwrite the original only if it hasn't changed in the meantime. Use when an IDE may be saving the file in parallel (e.g. editor on-save hook). |
| `-h`, `--help`                     | Print usage and exit.                                                                                                                                                                                     |

On first run, the CLI runs `bun install` automatically if the gem's `node_modules/` is missing.

### Ruby API

```ruby
ImmosquareCleaner.clean("path/to/your/file.rb")
```

## Rake Tasks

To clean every source file of a Rails app in bulk (onboarding, cleaner upgrade, large refactor):

```bash
bundle exec rake immosquare_cleaner:clean_app
```

The task is parallelized via threads (defaults to `min(nprocessors, 8)` since linters shell out and release the GVL). Override with:

```bash
CLEANER_THREADS=4 bundle exec rake immosquare_cleaner:clean_app
```

Generated/non-source folders (`app/assets/builds`, `app/assets/fonts`, `app/assets/images`, `coverage`, `db`, `log`, `node_modules`, `public`, `test`, `tmp`, `vendor`) and binary/lock files (`.lock`, `.lockb`, `.otf`, `.ttf`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.ico`, `.webp`, `.csv`) are skipped.


## Integration with Visual Studio Code & Cursor

Simply install the [immosquare-vscode](https://marketplace.visualstudio.com/items?itemName=immosquare.immosquare-vscode) extension from the VS Code marketplace.

That's it!

## Development

### TypeScript and ESLint

TypeScript 7 is installed as `@typescript/native`, but TypeScript 7.0 does not expose the stable programmatic API required by `typescript-eslint` and SonarJS. The `typescript` dependency therefore resolves to the fixed 6.0.3 npm tarball; using the tarball prevents `bun update --latest` from replacing the linter API. Remove this compatibility lock when `typescript-eslint` supports the TypeScript 7.1 API.

### Running Tests

```bash
bundle exec rake test
```

Coverage is off by default, so a local run stays fast and leaves no `coverage/` directory behind. Set `COVERAGE=true` to get an HTML report plus `coverage/lcov.info`:

```bash
COVERAGE=true bundle exec rake test
```

### Continuous Integration

`Jenkinsfile` runs the suite on every build through `bin/ci`, which is a repository script and is not shipped with the gem:

```bash
bin/ci init   # bundle install && bun install --frozen-lockfile
bin/ci test   # bundle exec rake test
```

`bin/ci init` installs the JS toolchain too: the JS, Prettier and Markdown tests call the library directly rather than the `immosquare-cleaner` executable, so nothing provisions `node_modules/` for them. Both sub-commands skip the `development` bundler group — anything the suite needs belongs to the `test` group of the `Gemfile`. The RVM setup only applies on a build agent, so `bin/ci` behaves the same on a laptop.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/immosquare/immosquare-cleaner).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
