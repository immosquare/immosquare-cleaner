# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

coverage_helper = File.expand_path("test/coverage_helper", __dir__)

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.ruby_opts << "-r#{coverage_helper}"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
