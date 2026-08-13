source "https://rubygems.org"

gemspec

group :development do
  gem "bundler"
  ##============================================================##
  ## Language Server Protocol : https://shopify.github.io/ruby-lsp/
  ##============================================================##
  gem "ruby-lsp"
end

##============================================================##
## Anything the tests need belongs here and not in :development,
## which the CI skips (cf. bin/ci). rake is not dev comfort here:
## the suite is a Rake::TestTask, so `rake test` is the runner.
##============================================================##
group :test do
  gem "rake"
  gem "simplecov",      :require => false
  gem "simplecov-lcov", :require => false
  gem "test-unit"
end
