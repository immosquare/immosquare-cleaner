# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"
require "tmpdir"

class RubyTargetTest < Test::Unit::TestCase

  def setup
    @root = Dir.mktmpdir("immosquare_cleaner_ruby_target_test")
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  ##============================================================##
  ## A gem must keep working on the oldest Ruby it accepts: its
  ## gemspec minimum wins over the .ruby-version used to develop it.
  ## Autocorrecting for the newer Ruby would rewrite `_1` into `it`,
  ## which Ruby 3.2 rejects.
  ##============================================================##
  def test_gemspec_minimum_wins_over_ruby_version
    write("my-gem.gemspec", "spec.required_ruby_version = Gem::Requirement.new(\">= 3.2.6\")\n")
    write(".ruby-version", "ruby-3.4.7\n")

    assert_equal("3.2", detect("lib/my-gem/version.rb"))
  end

  def test_ruby_version_applies_to_an_app_without_gemspec
    write("Gemfile", "source \"https://rubygems.org\"\n")
    write(".ruby-version", "ruby-3.3.6\n")

    assert_equal("3.3", detect("app/models/concerns/user.rb"))
  end

  ##============================================================##
  ## A folder that holds several projects must not impose its
  ## .ruby-version on a project that declares none.
  ##============================================================##
  def test_lookup_stops_at_the_project_root
    write(".ruby-version", "2.7.8\n")
    write("app/Gemfile", "source \"https://rubygems.org\"\n")

    assert_equal(running_release, detect("app/lib/tool.rb"))
  end

  ##============================================================##
  ## A version RuboCop cannot target must not stop cleaning: the
  ## running Ruby is used and the mismatch is reported.
  ##============================================================##
  def test_unsupported_declared_version_falls_back_to_the_running_ruby
    write("old-gem.gemspec", "spec.required_ruby_version = \">= 1.8.7\"\n")

    target = nil
    _stdout, stderr = capture_output { target = detect("lib/old_gem.rb") }

    assert_equal(running_release, target)
    assert_match(/1\.8/, stderr)
  end

  private

  def write(path, content)
    full_path = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def detect(path)
    ImmosquareCleaner::RubyTarget.detect(File.join(@root, path))
  end

  def running_release
    ImmosquareCleaner::RubyTarget.release(RUBY_VERSION)
  end

end
