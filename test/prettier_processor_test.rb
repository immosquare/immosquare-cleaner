# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

class PrettierProcessorTest < Test::Unit::TestCase

  def setup
    @tmp_dir = "test/tmp_prettier_processor_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## A .css file matches no specific processor, so it falls
  ## through to the Prettier fallback rather than being routed
  ## by the registry scan.
  ##============================================================##
  def test_css_dispatches_to_prettier_fallback
    assert_equal(ImmosquareCleaner::Processors::Prettier, ImmosquareCleaner.send(:processor_for, "x.css"))
  end

  ##============================================================##
  ## End-to-end: minified CSS routed to the Prettier fallback is
  ## expanded by `bun prettier` using the gem's prettier.yml
  ## (tabWidth 2 → 2-space indent, semi true for CSS declarations,
  ## endOfLine lf, trailing newline). The exact output is pinned
  ## from the real prettier run, not guessed.
  ##============================================================##
  def test_css_formatted_by_prettier
    file_path = File.join(@tmp_dir, "test.css")
    minified  = "a{color:red}"
    File.write(file_path, minified)

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_not_equal(minified, content)
    assert_equal("a {\n  color: red;\n}\n", content)
  end

end
