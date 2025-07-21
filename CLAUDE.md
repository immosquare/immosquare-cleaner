# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `immosquare-cleaner`, a Ruby gem that provides comprehensive code formatting and linting for Rails applications. It supports multiple file formats including Ruby, ERB, JavaScript, JSON, YAML, Markdown, and other formats via Prettier.

## Key Architecture

The gem is structured around a central `ImmosquareCleaner` module with a `clean` method that dispatches to different processors based on file extensions:

- **Ruby files** (`.rb`, `.rake`, Gemfiles, etc.): Processed with RuboCop
- **ERB files** (`.html.erb`, `.html`): Processed with htmlbeautifier + erb_lint
- **JavaScript files** (`.js`, `.mjs`, `.js.erb`): Processed with ESLint (and erb_lint for `.js.erb`)
- **JSON files**: Formatted using custom JSON beautifier
- **YAML files** (in locales folders): Processed with ImmosquareYaml
- **Markdown files** (`.md`, `.md.erb`): Custom markdown processor
- **Other formats**: Processed with Prettier

## Development Commands

### Gem Commands
```bash
# Clean a specific file
bundle exec immosquare-cleaner path/to/file.rb

# Clean all Rails app files
rake immosquare_cleaner:clean_app

# Update dependencies and clean package.json
bun run morning
```

### Dependencies Management
```bash
# Update Ruby dependencies
bundle update && bundle clean --force

# Update JavaScript dependencies  
bun update

# Install JavaScript dependencies (auto-runs if node_modules missing)
bun install
```

## Configuration

The gem can be configured via `config/initializers/immosquare-cleaner.rb`:

```ruby
ImmosquareCleaner.config do |config|
  config.rubocop_options        = "--your-rubocop-options-here"
  config.htmlbeautifier_options = "--your-htmlbeautifier-options-here"
  config.erblint_options        = "--your-erblint-options-here"
  config.exclude_files          = ["db/schema.rb", "db/seeds.rb"]
end
```

## Important Implementation Details

### Ruby Version Handling
- The gem dynamically creates version-specific config files (`rubocop-3.4.1.yml`, `erb-lint-3.4.1.yml`)
- Uses `parser_prism` for Ruby 3.3+ and `parser_whitequark` for older versions

### ESLint Workaround for V9+
- ESLint V9+ has a "File ignored because outside of base path" issue
- The gem copies JS files to a temporary folder within the gem directory before linting
- Files are cleaned up after processing

### Custom RuboCop Cops
The gem includes custom cops in `linters/rubocop/cop/custom_cops/style/`:
- `AlignAssignments`: Aligns variable assignments
- `CommentNormalization`: Normalizes comment formatting
- `FontAwesomeNormalization`: Standardizes Font Awesome usage

### File Processing Strategy
- All processors ensure files end with a single newline via `File.normalize_last_line`
- Temporary files are cleaned up after processing
- Commands are executed from the gem root directory for consistent path resolution

## Prerequisites

- **Bun**: Required for JavaScript tooling (ESLint, Prettier)
- **Ruby 3.2.6+**: Minimum Ruby version
- **Bundle**: For Ruby dependency management

## File Structure

- `lib/immosquare-cleaner.rb`: Main module with file processing logic
- `lib/immosquare-cleaner/configuration.rb`: Configuration class
- `lib/immosquare-cleaner/markdown.rb`: Custom markdown processor
- `lib/tasks/immosquare_cleaner.rake`: Rails integration tasks
- `linters/`: All linter configuration files
- `bin/immosquare-cleaner`: CLI executable