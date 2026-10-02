require_relative "lib/immosquare-cleaner/version"

Gem::Specification.new do |spec|
  spec.platform       = Gem::Platform::RUBY
  spec.license        = "MIT"
  spec.name           = "immosquare-cleaner"
  spec.version        = ImmosquareCleaner::VERSION.dup
  spec.authors        = ["immosquare"]
  spec.email          = ["jules@immosquare.com"]
  spec.homepage       = "https://github.com/immosquare/immosquare-cleaner"
  spec.summary        = "One command to format every file of a repository, built to run as an AI agent hook."
  spec.description    = "immosquare-cleaner formats Ruby, ERB, JS/TS, Rust, Go, TOML, Markdown, Shell, JSON, YAML and CSS files with one consistent house style, delegating each format to the right tool (RuboCop, erb_lint, ESLint, rustfmt, gofmt, taplo, shfmt, Prettier). Run it on a file, a whole repository, on save, or as a Claude Code, Cursor or Gemini CLI hook so every file an AI agent writes comes out formatted."
  spec.metadata       = {
    "source_code_uri" => "https://github.com/immosquare/immosquare-cleaner",
    "changelog_uri"   => "https://github.com/immosquare/immosquare-cleaner/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/immosquare/immosquare-cleaner/issues"
  }

  ##============================================================##
  ## we add package.json so that the gems is autonomous to launch
  ## js lib prettier, eslint
  ##
  ## bin/ is listed file by file: bin/ci is the CI entry point,
  ## it has no business being shipped to the people installing the gem.
  ##============================================================##
  spec.files          = Dir["lib/**/*", "linters/**/*"] + ["bin/immosquare-cleaner", "package.json", ".erb_linters", "LICENSE"]
  spec.executables    = ["immosquare-cleaner"]
  spec.require_paths  = ["lib", "linters"]

  spec.add_dependency("erb_lint",              ">= 0.7",  "<=1000.0")
  spec.add_dependency("htmlbeautifier",        ">= 1.4",  "<=1000.0")
  spec.add_dependency("immosquare-extensions", ">= 0.1",  "<=1000.0")
  spec.add_dependency("immosquare-yaml",       ">= 0.1",  "<=1000.0")
  spec.add_dependency("parallel",              ">= 1.0",  "<=1000.0")
  spec.add_dependency("prism",                 ">= 1.3", "<=1000.0")
  spec.add_dependency("rubocop",               ">= 1.68", "<=1000.0")

  spec.required_ruby_version = Gem::Requirement.new(">= 3.2.6")
end
