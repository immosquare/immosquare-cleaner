require_relative "lib/immosquare-cleaner/version"

Gem::Specification.new do |spec|
  spec.license        = "MIT"
  spec.name           = "immosquare-cleaner"
  spec.version        = ImmosquareCleaner::VERSION.dup
  spec.authors        = ["immosquare"]
  spec.email          = ["jules@immosquare.com"]

  spec.summary        = "A gem to lint and organize files in a Rails application."
  spec.description    = "Immosquare-cleaner streamlines Rails applications by running tools like RuboCop, ERBLint, Stylelint and more. It ensures code quality, readability, and consistency across the application."

  spec.homepage       = "https://github.com/immosquare/Immosquare-cleaner"


  ##===========================================================================##
  ## we add package.json so that the gems is autonomous to launch prettier
  ## & eslint (all the necessary libs are in the node_modules folder)
  ##===========================================================================##
  spec.files          = Dir["lib/**/*", "bin/*", "linters/**/*"] + ["package.json"] + Dir["node_modules/**/*", "node_modules/.bin/**/*"]
  spec.executables    = ["immosquare-cleaner"]
  spec.require_paths  = ["lib", "linters"]

  spec.add_dependency("erb_lint", "~> 0")
  spec.add_dependency("htmlbeautifier", "~> 1")
  spec.add_dependency("immosquare-extensions", "~> 0", ">= 0.1.18")
  spec.add_dependency("immosquare-yaml", "~> 0", ">= 0.1.26")
  spec.add_dependency("rubocop", "~> 1", ">= 1.62.1")



  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.2")
end
