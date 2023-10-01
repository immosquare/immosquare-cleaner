# ImmosquareCleaner

A meticulously crafted Ruby gem to enhance the cleanliness and structure of your project's files. This tool ensures consistency and uniformity across various formats, including Ruby, ERB, YAML, Markdown, JSON, JS, CSS, SASS, LESS, and other formats supported by Prettier.

## Supported Formats

The cleaner recognizes and caters to various file formats:

| File Type | File Extension                                                                                                                                                                        | Processor                                                    |
|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| ERB       | `.html.erb`                                                                                                                                                                           | [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier) && [erb-lint](https://github.com/Shopify/erb-lint)              |
| Ruby      | `.rb`, `.rake`, `Gemfile`, `Rakefile`, `.axlsx`, `.gemspec`, `.ru`, `.podspec`, `.jbuilder`, `.rabl`, `.thor`, `config.ru`, `Berksfile`, `Capfile`, `Guardfile`, `Podfile`, `Thorfile`, `Vagrantfile` | [rubocop](https://rubocop.org/)                              |
| YAML      | `.yml` (only files in locales folder)                                                                                                                                                                 | [ImmosquareYaml](https://github.com/IMMOSQUARE/immosquare-yaml) |
| JS        | `.js`                                                                                                                                                                                | [eslint](https://eslint.org/)                                |
| JSON      | `.json`                                                                                                                                                                              | [ImmosquareExtensions](https://github.com/IMMOSQUARE/immosquare-extensions) |
| Others    | Any other format                                                                                                                                                                     | [prettier](https://prettier.io/)                             |


## Linter Configurations

You can view the specific configurations for all supported linters in the [linters folder](https://github.com/IMMOSQUARE/immosquare-cleaner/tree/main/linters) of the repository.

## Installation

**Prerequisite**: Please be sure to have [bun](https://bun.sh/) installed. This is necessary to launch eslint & prettier commands.

For the Ruby gem:

```ruby
gem "immosquare-cleaner"
```

Then execute:

```bash
$ bundle install
```

For the npm module:

Add `immosquare-cleaner` to your development dependencies. For instance, using `bun`:

```bash
$ bun add immosquare-cleaner
```

## Usage

To clean a specific file:

```ruby
ImmosquareCleaner.clean("path/to/your/file.rb")
```

### Configuration

Tailor the behavior of the gem/module with the provided configuration options:

```ruby
ImmosquareCleaner.config do |config|
  # Set custom rubocop options
  config.rubocop_options = "--your-rubocop-options-here"
  # Set custom htmlbeautifier options
  config.htmlbeautifier_options = "--your-htmlbeautifier-options-here"
  # Set custom erblint options
  config.erblint_options = "--your-erblint-options-here"
end
```

## Integration with Visual Studio Code

Automate the cleaning process for all files upon saving in VS Code:

1. Install the [Run on Save](https://github.com/emeraldwalk/vscode-runonsave) extension from the VS Code marketplace.
2. Add the following configuration to your `settings.json` in VS Code:

```json
"emeraldwalk.runonsave": {
  "commands": [
    {
      "match": ".*",
      "cmd": "if bundle info immosquare-cleaner &>/dev/null; then bundle exec immosquare-cleaner '${file}'; else echo 'please install the gem immosquare-cleaner'; fi"
    }
  ]
}
```

With the above, every time you save a file in VS Code, it will automatically be cleaned using `immosquare-cleaner`.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/IMMOSQUARE/immosquare-cleaner).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
