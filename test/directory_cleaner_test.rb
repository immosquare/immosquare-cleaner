# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"
require "tmpdir"

class DirectoryCleanerTest < Test::Unit::TestCase

  def setup
    @root = Dir.mktmpdir("immosquare_cleaner_directory_test")
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  ##============================================================##
  ## Test code is source code: it is cleaned like the rest of the
  ## repository. Fixtures are not: YAML fixtures hold ERB tags
  ## Prettier would break, and sample files are compared byte for
  ## byte by the tests that load them.
  ##============================================================##
  def test_test_code_is_cleaned_but_fixtures_are_not
    files = [
      "test/models/user_test.rb",
      "spec/models/user_spec.rb",
      "test/provider_test.go",
      "test/fixtures/users.yml",
      "test/fixtures/files/sample.json",
      "spec/fixtures/sample.json"
    ]
    files.each do |path|
      FileUtils.mkdir_p(File.join(@root, File.dirname(path)))
      File.write(File.join(@root, path), "\n")
    end

    selected = ImmosquareCleaner::DirectoryCleaner.new(@root).file_paths.map {|path| path.delete_prefix("#{@root}/") }

    assert_equal(["spec/models/user_spec.rb", "test/models/user_test.rb", "test/provider_test.go"], selected)
  end

end
