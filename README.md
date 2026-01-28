# Immosquare-cleaner

A meticulously crafted Ruby gem to enhance the cleanliness and structure of your project's files. This tool ensures consistency and uniformity across various formats, including Ruby, ERB, YAML, Markdown, JSON, JS, CSS, SASS, LESS, and other formats supported by Prettier.

## Supported Formats

The cleaner recognizes and caters to various file formats:

| File Type   | File Extension                                                                                                                                                                                                    | Processor                                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ERB         | `.html.erb` , `.html`                                                                                                                                                                                             | [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier) && [erb-lint](https://github.com/Shopify/erb-lint) |
| Ruby        | `.rb`, `.rake`, `Gemfile`, `Rakefile`, `Brewfile`, `.axlsx`, `.gemspec`, `.ru`, `.podspec`, `.jbuilder`, `.rabl`, `.thor`, `config.ru`, `Berksfile`, `Capfile`, `Guardfile`, `Podfile`, `Thorfile`, `Vagrantfile` | [rubocop](https://rubocop.org/)                                                                                     |
| YAML        | `.yml` (only files in locales folder)                                                                                                                                                                             | [ImmosquareYaml](https://github.com/immosquare/immosquare-yaml)                                                     |
| JS          | `.js`, `.mjs`, `js.erb`, `.jsx`, `.ts`, `.ts.erb`, `.tsx`                                                                                                                                                         | [eslint](https://eslint.org/)                                                                                       |
| JSON        | `.json`                                                                                                                                                                                                           | [ImmosquareExtensions](https://github.com/immosquare/immosquare-extensions)                                         |
| Markdown    | `.md`, `.md.erb`                                                                                                                                                                                                  | [ImmosquareCleaner](https://github.com/immosquare/immosquare-cleaner)                                               |
| Shell       | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                                                                                                                                               | [shfmt](https://github.com/mvdan/sh)                                                                                |
| Others      | Any other format                                                                                                                                                                                                  | [prettier](https://prettier.io/)                                                                                    |

## Linter Configurations

You can view the specific configurations for all supported linters in the [linters folder](https://github.com/immosquare/immosquare-cleaner/tree/main/linters) of the repository.

### Custom RuboCop Cops

The gem includes custom RuboCop cops:

| Cop                                         | Description                                                   |
| ------------------------------------------- | ------------------------------------------------------------- |
| `CustomCops/Style/CommentNormalization`     | Normalizes comment formatting                                 |
| `CustomCops/Style/FontAwesomeNormalization` | Standardizes Font Awesome class names (fas -> fa-solid)       |
| `CustomCops/Style/AlignAssignments`         | Aligns consecutive variable assignments (disabled by default) |

### Custom erb_lint Linters

The gem includes custom erb_lint linters for ERB files:

| Linter                       | Description                                                                              |
| ---------------------------- | ---------------------------------------------------------------------------------------- |
| `CustomSingleLineIfModifier` | Converts `<% if cond %><%= x %><% end %>` to `<%= x if cond %>`                          |
| `CustomHtmlToContentTag`     | Converts `<div class="x"><%= y %></div>` to `<%= content_tag(:div, y, :class => "x") %>` |

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

### Ruby API

```ruby
ImmosquareCleaner.clean("path/to/your/file.rb")
```

## Rake Tasks

To clean rails project files:

```ruby
rake immosquare_cleaner:clean_app
```


## Integration with Visual Studio Code & Cursor

Simply install the [immosquare-vscode](https://marketplace.visualstudio.com/items?itemName=immosquare.immosquare-vscode) extension from the VS Code marketplace.

That's it!

## Development

### Running Tests

```bash
bundle exec rake test
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/immosquare/immosquare-cleaner).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
