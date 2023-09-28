require_relative "lib/immosquare-cleaner/version"


Gem::Specification.new do |spec|
  spec.license       = "MIT"
  spec.name          = "immosquare-cleaner"
  spec.version       = ImmosquareCleaner::VERSION.dup
  spec.authors       = ["IMMO SQUARE"]
  spec.email         = ["jules@immosquare.com"]

  spec.summary          = "test"
  spec.description      = "test"

  
  spec.homepage          = "https://github.com/IMMOSQUARE/Immosquare-cleaner"
  
  
  spec.files             = %w(Rakefile README.md) + Dir.glob("{bin,lib}/**/*")
  spec.executables       = Dir["bin/**"].map { |f| File.basename(f) }
  spec.require_paths     = ["lib"]


  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.2")
  

end