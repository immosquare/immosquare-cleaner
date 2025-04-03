# Immosquare-cleaner

A meticulously crafted Ruby gem to enhance the cleanliness and structure of your project's files. This tool ensures consistency and uniformity across various formats, including Ruby, ERB, YAML, Markdown, JSON, JS, CSS, SASS, LESS, and other formats supported by Prettier.

## Supported Formats

The cleaner recognizes and caters to various file formats:

| File Type   | File Extension                                                                                                                                                                                        | Processor                                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ERB         | `.html.erb` , `.html`                                                                                                                                                                                 | [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier) && [erb-lint](https://github.com/Shopify/erb-lint) |
| Ruby        | `.rb`, `.rake`, `Gemfile`, `Rakefile`, `.axlsx`, `.gemspec`, `.ru`, `.podspec`, `.jbuilder`, `.rabl`, `.thor`, `config.ru`, `Berksfile`, `Capfile`, `Guardfile`, `Podfile`, `Thorfile`, `Vagrantfile` | [rubocop](https://rubocop.org/)                                                                                     |
| YAML        | `.yml` (only files in locales folder)                                                                                                                                                                 | [ImmosquareYaml](https://github.com/immosquare/immosquare-yaml)                                                     |
| JS          | `.js`, `.mjs`                                                                                                                                                                                         | [eslint](https://eslint.org/)                                                                                       |
| JSON        | `.json`                                                                                                                                                                                               | [ImmosquareExtensions](https://github.com/immosquare/immosquare-extensions)                                         |
| Markdown    | `.md`, `.md.erb`                                                                                                                                                                                      | [ImmosquareCleaner](https://github.com/immosquare/immosquare-cleaner)                                               |
| Others      | Any other format                                                                                                                                                                                      | [prettier](https://prettier.io/)                                                                                    |

## Linter Configurations

You can view the specific configurations for all supported linters in the [linters folder](https://github.com/immosquare/immosquare-cleaner/tree/main/linters) of the repository.

## Installation

**Prerequisite**: Please be sure to have [bun](https://bun.sh/) installed. (This is necessary to launch eslint & prettier commands.)

Add the gem in your development group in the Gemfile:

```ruby
group :development do
  ...
  gem "immosquare-cleaner"
  ...
end
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

To clean a specific file:

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

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/immosquare/immosquare-cleaner).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
