# ImmosquareCleaner

A professional Ruby gem crafted meticulously to enhance the cleanliness and structure of your project's files. Whether they're Ruby, ERB, YAML, Markdown, JSON, JS, CSS, SASS, LESS, or any format supported by Prettier, this gem ensures consistency and uniformity.

## Features

- 🧹 **Automated File Cleaning:** Formats and auto-corrects files.
- 📝 **Extensive Format Support:** Ruby, ERB, YAML, Markdown, JSON, JS, CSS, SASS, LESS and any format supported by Prettier.
- 🎨 **Prettier Integration:** Seamlessly integrates if `npx` and `prettier` are installed.
- 🚀 **Rails Friendly:** Comes with an integrated Railtie for smooth operation within Rails projects.
- 🔧 **Highly Configurable:** Offers various configuration options for a tailored cleaning experience.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'immosquare-cleaner'
```

And then execute:

```
$ bundle install
```

## Usage

To clean a specific file:

```ruby
ImmosquareCleaner.clean("path/to/your/file.rb")
```

### Configuration

Tailor the behavior of the gem using the provided configuration options:

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

### Supported File Formats

The cleaner recognizes and caters to various file formats:

- Ruby: `.rb`, `.rake`, `Gemfile`, and more
- ERB: `.html.erb`
- YAML: especially locales (`locales/*.yml`)
- Web Development: JSON, JS, CSS, SASS, LESS
- And any other format supported by Prettier

## Integrating with Visual Studio Code

You can automate the cleaning process for all files upon saving in VS Code:

1. Install the [Run on Save](https://github.com/emeraldwalk/vscode-runonsave) extension from the VS Code marketplace.
2. Add the following configuration to your `settings.json` in VS Code:

```json
"emeraldwalk.runonsave": {
  "commands": [
    {
      "match": ".*",
      "cmd": "cd ${workspaceFolder} && if [[ '${file}' == ${workspaceFolder}* ]] && bundle info immosquare-cleaner &>/dev/null; then bundle exec immosquare-cleaner ${file}; fi"
    }
  ]
}
```

With the above, every time you save a file in VS Code, it will automatically be cleaned using `immosquare-cleaner`.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/IMMOSQUARE/immosquare-cleaner).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
