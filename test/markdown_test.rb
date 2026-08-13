# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

class MarkdownTest < Test::Unit::TestCase

  def setup
    @tmp_dir = "test/tmp_markdown_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## Every column is padded to the width of its widest cell, and
  ## the separator row is filled with dashes over that same width.
  ##============================================================##
  def test_table_columns_are_aligned
    source = <<~MARKDOWN
      | Name | Description |
      | - | - |
      | a | a very long description |
    MARKDOWN

    expected = <<~MARKDOWN
      | Name | Description             |
      | ---- | ----------------------- |
      | a    | a very long description |
    MARKDOWN

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## An empty cell keeps its column: dropping it would shift every
  ## following cell one column to the left and file values under
  ## the wrong header.
  ##============================================================##
  def test_empty_cells_keep_their_column
    source = <<~MARKDOWN
      |         | Paris | Metz |
      | ------- | ----- | ---- |
      | Country | FR    | FR   |
      | Region  |       | GE   |
    MARKDOWN

    expected = <<~MARKDOWN
      |         | Paris | Metz |
      | ------- | ----- | ---- |
      | Country | FR    | FR   |
      | Region  |       | GE   |
    MARKDOWN

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## An empty cell stays empty: filling it with dashes would make
  ## the row read as a separator.
  ##============================================================##
  def test_empty_cell_is_not_filled_with_dashes
    source = <<~MARKDOWN
      | Key | Value |
      | --- | ----- |
      |     | 42    |
    MARKDOWN

    assert_true(clean(source).include?("|     | 42    |"))
  end

  ##============================================================##
  ## A row with fewer cells than the widest one is padded with
  ## empty cells rather than producing a ragged table.
  ##============================================================##
  def test_short_rows_are_padded
    source = <<~MARKDOWN
      | A | B | C |
      | - | - | - |
      | 1 |
    MARKDOWN

    expected = <<~MARKDOWN
      | A | B | C |
      | - | - | - |
      | 1 |   |   |
    MARKDOWN

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## A table closing the file (no trailing text line) is still
  ## formatted — the buffered rows are flushed at EOF.
  ##============================================================##
  def test_table_at_end_of_file
    source = <<~MARKDOWN
      Intro

      | A | Long header |
      | - | - |
    MARKDOWN

    expected = <<~MARKDOWN
      Intro

      | A | Long header |
      | - | ----------- |
    MARKDOWN

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## Pipes inside a fenced code block belong to the snippet, not
  ## to a table: the block is emitted verbatim.
  ##============================================================##
  def test_fenced_code_block_is_untouched
    source = <<~MARKDOWN
      ```ruby
      | a | b |
      list = [1, 2].map {|i| i }
      ```
    MARKDOWN

    assert_equal(source, clean(source))
  end

  ##============================================================##
  ## The closing fence must use the same marker as the opening
  ## one: a ~~~ line shown inside a ``` block (documenting
  ## markdown itself) does not close the fence.
  ##============================================================##
  def test_nested_fence_marker_does_not_close_the_block
    source = <<~MARKDOWN
      ```markdown
      ~~~
      | a | b |
      ~~~
      ```

      | A | Long header |
      | - | - |
    MARKDOWN

    expected = <<~MARKDOWN
      ```markdown
      ~~~
      | a | b |
      ~~~
      ```

      | A | Long header |
      | - | ----------- |
    MARKDOWN

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## A blank line is inserted after a list when the next line is
  ## regular text, and trailing whitespace is stripped everywhere.
  ##============================================================##
  def test_blank_line_after_list_and_trailing_whitespace
    source   = "Intro\n- one   \n- two\nText right after the list\n"
    expected = "Intro\n- one\n- two\n\nText right after the list\n"

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## The first line of the file has no predecessor, which must not
  ## exempt it from the trailing whitespace stripping.
  ##============================================================##
  def test_trailing_whitespace_on_first_line
    assert_equal("Intro\nText\n", clean("Intro   \nText\n"))
  end

  private

  ##============================================================##
  ## Markdown.clean reads from disk and returns the cleaned
  ## content without writing it back.
  ##============================================================##
  def clean(source)
    file_path = File.join(@tmp_dir, "file.md")
    File.write(file_path, source)
    ImmosquareCleaner::Markdown.clean(file_path)
  end

end
