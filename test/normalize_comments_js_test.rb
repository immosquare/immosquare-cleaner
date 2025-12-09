# frozen_string_literal: true

require "test-unit"
require "tempfile"
require "fileutils"

class NormalizeCommentsJsTest < Test::Unit::TestCase

  LINTER_PATH = File.expand_path("../linters/normalize-comments.mjs", __dir__)
  BORDER_LINE = "//============================================================//"

  ##============================================================##
  ## Helper to run the linter on JS source and return the result
  ##============================================================##
  def run_linter(source)
    Tempfile.create(["test", ".js"]) do |file|
      file.write(source)
      file.flush

      system("bun", LINTER_PATH, file.path, :out => File::NULL, :err => File::NULL)

      File.read(file.path)
    end
  end

  ##============================================================##
  ## Basic formatting
  ##============================================================##
  def test_simple_comment_gets_borders
    source = <<~JS
      // My comment
      const x = 1
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // My comment
      #{BORDER_LINE}
      const x = 1
    JS

    assert_equal(expected, result)
  end

  def test_comment_without_space_gets_normalized
    source = <<~JS
      //My comment without space
      const x = 1
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // My comment without space
      #{BORDER_LINE}
      const x = 1
    JS

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Idempotency - already correct format should not change
  ##============================================================##
  def test_already_formatted_comment_unchanged
    source = <<~JS
      #{BORDER_LINE}
      // Already formatted
      #{BORDER_LINE}
      const x = 1
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

  def test_multiple_runs_are_idempotent
    source = <<~JS
      #{BORDER_LINE}
      // Test comment
      #{BORDER_LINE}
      const x = 1
    JS

    result1 = run_linter(source)
    result2 = run_linter(result1)
    result3 = run_linter(result2)

    assert_equal(source, result1)
    assert_equal(source, result2)
    assert_equal(source, result3)
  end

  ##============================================================##
  ## Fixing duplicate borders
  ##============================================================##
  def test_double_borders_get_fixed
    source = <<~JS
      #{BORDER_LINE}
      #{BORDER_LINE}
      // Double borders
      #{BORDER_LINE}
      #{BORDER_LINE}
      const x = 1
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // Double borders
      #{BORDER_LINE}
      const x = 1
    JS

    assert_equal(expected, result)
  end

  def test_triple_borders_get_fixed
    source = <<~JS
      #{BORDER_LINE}
      #{BORDER_LINE}
      #{BORDER_LINE}
      // Triple borders
      #{BORDER_LINE}
      #{BORDER_LINE}
      #{BORDER_LINE}
      const x = 1
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // Triple borders
      #{BORDER_LINE}
      const x = 1
    JS

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Sprockets directives should be ignored
  ##============================================================##
  def test_sprockets_require_not_modified
    source = <<~JS
      //= require jquery
      //= require_tree .

      #{BORDER_LINE}
      // My code
      #{BORDER_LINE}
      const x = 1
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

  def test_sprockets_link_not_modified
    source = <<~JS
      //= link application.js

      const x = 1
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

  ##============================================================##
  ## Triple-slash comments (TypeScript) should be ignored
  ##============================================================##
  def test_triple_slash_reference_not_modified
    source = <<~JS
      /// <reference types="node" />

      #{BORDER_LINE}
      // My code
      #{BORDER_LINE}
      const x = 1
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

  ##============================================================##
  ## End-of-line comments should be ignored
  ##============================================================##
  def test_end_of_line_comment_not_modified
    source = <<~JS
      const x = 1 // This is an end-of-line comment
      const y = 2
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

  ##============================================================##
  ## Indentation preservation
  ##============================================================##
  def test_indented_comment_preserves_indentation
    source = <<~JS
      function foo() {
        // Indented comment
        const x = 1
      }
    JS

    result = run_linter(source)

    expected = <<~JS
      function foo() {
        #{BORDER_LINE}
        // Indented comment
        #{BORDER_LINE}
        const x = 1
      }
    JS

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Multi-line comments
  ##============================================================##
  def test_multiline_comment_block
    source = <<~JS
      // First line
      // Second line
      // Third line
      const x = 1
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // First line
      // Second line
      // Third line
      #{BORDER_LINE}
      const x = 1
    JS

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Multiple separate comment blocks
  ##============================================================##
  def test_multiple_comment_blocks
    source = <<~JS
      // First block
      const x = 1

      // Second block
      const y = 2
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // First block
      #{BORDER_LINE}
      const x = 1

      #{BORDER_LINE}
      // Second block
      #{BORDER_LINE}
      const y = 2
    JS

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Empty comment handling
  ##============================================================##
  def test_empty_comment_gets_placeholder
    source = <<~JS
      //
      const x = 1
    JS

    result = run_linter(source)

    expected = <<~JS
      #{BORDER_LINE}
      // ...
      #{BORDER_LINE}
      const x = 1
    JS

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Block comments (/* */) should be ignored
  ##============================================================##
  def test_block_comment_not_modified
    source = <<~JS
      /* This is a block comment */
      const x = 1
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

  def test_multiline_block_comment_not_modified
    source = <<~JS
      /*
       * Multi-line block comment
       * Should not be modified
       */
      const x = 1
    JS

    result = run_linter(source)
    assert_equal(source, result)
  end

end
