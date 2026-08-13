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
  ## A frontmatter is YAML, not markdown: it is emitted verbatim,
  ## with no blank line slipped in after its opening fence.
  ##============================================================##
  def test_frontmatter_is_emitted_verbatim
    source = <<~MARKDOWN
      ---
      name: example
      description: test
      ---

      # Title
    MARKDOWN

    assert_equal(source, clean(source))
  end

  ##============================================================##
  ## No blank line before the closing fence when the last key holds
  ## a list: inside a frontmatter, `---` closes the YAML document,
  ## it does not end a markdown list.
  ##============================================================##
  def test_frontmatter_closing_fence_after_a_list
    source = <<~MARKDOWN
      ---
      paths:
        - "**/*.html.erb"
        - "**/*.html"
      ---

      # Title
    MARKDOWN

    assert_equal(source, clean(source))
  end

  ##============================================================##
  ## Leading blank lines inside the frontmatter are dropped: never
  ## meaningful in YAML, and earlier versions injected one there by
  ## taking the opening `---` for a list item. Removing it repairs
  ## the files that already carry it.
  ##============================================================##
  def test_frontmatter_leading_blank_line_is_removed
    source = <<~MARKDOWN
      ---

      name: example
      ---

      # Title
    MARKDOWN

    expected = <<~MARKDOWN
      ---
      name: example
      ---

      # Title
    MARKDOWN

    assert_equal(expected, clean(source))
  end

  ##============================================================##
  ## `---` on the first line with no closing fence is a thematic
  ## break, not a frontmatter: the rest of the file keeps being
  ## processed instead of being emitted verbatim to the end.
  ##============================================================##
  def test_leading_thematic_break_is_not_a_frontmatter
    assert_equal(
      "---\n- one\n\nText right after the list\n",
      clean("---\n- one\nText right after the list\n")
    )
  end

  ##============================================================##
  ## A list marker is `*`, `+` or `-` followed by a space. A
  ## thematic break and an emphasis opening a line are neither, so
  ## no blank line is inserted after them.
  ##============================================================##
  def test_thematic_break_and_emphasis_are_not_list_items
    source = <<~MARKDOWN
      Intro

      ---
      Text after a thematic break.

      *An emphasised note.*
      Next line.
    MARKDOWN

    assert_equal(source, clean(source))
  end

  ##============================================================##
  ## Cleaning an already-cleaned file returns identical content —
  ## the formatting is a fixed point, so the hook that runs on every
  ## save never keeps rewriting the same file.
  ##============================================================##
  def test_idempotent
    source = <<~MARKDOWN
      ---

      name: example
      ---

      # Title

      | A | Long header |
      | - | - |
      |   | x |

      - one
      Text right after the list
    MARKDOWN

    once = clean(source)

    assert_equal(once, clean(once))
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
