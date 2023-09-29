require_relative "lib/immosquare-cleaner/version"

Gem::Specification.new do |spec|
  spec.license        = "MIT"
  spec.name           = "immosquare-cleaner"
  spec.version        = ImmosquareCleaner::VERSION.dup
  spec.authors        = ["IMMO SQUARE"]
  spec.email          = ["jules@immosquare.com"]

  spec.summary        = "A gem to lint and organize files in a Rails application."
  spec.description    = "Immosquare-cleaner streamlines Rails applications by running tools like RuboCop, ERBLint, Stylelint and more. It ensures code quality, readability, and consistency across the application."


  spec.homepage       = "https://github.com/IMMOSQUARE/Immosquare-cleaner"
  
  
  spec.files          = ["Rakefile", "README.md"] + Dir.glob("{bin,lib}/**/*")
  spec.executables    = Dir["bin/**"].map {|f| File.basename(f) }
  spec.require_paths  = ["lib"]

  spec.add_dependency("erb_lint")
  spec.add_dependency("htmlbeautifier")
  spec.add_dependency("immosquare-rubocop")

  
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.2")
  
  spec.metadata["rubygems_mfa_required"] = "true"
end

