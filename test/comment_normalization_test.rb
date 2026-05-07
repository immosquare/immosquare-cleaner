# frozen_string_literal: true

require "test-unit"
require "rubocop"
require_relative "../linters/rubocop/cop/custom_cops/style/comment_normalization"

class CommentNormalizationTest < Test::Unit::TestCase

  ##============================================================##
  ## Runs the cop on the source and returns the corrected source.
  ##============================================================##
  def autocorrect(source)
    processed    = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    cop          = RuboCop::Cop::CustomCops::Style::CommentNormalization.new
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], :raise_error => true)
    report       = commissioner.investigate(processed)

    corrector = RuboCop::Cop::Corrector.new(processed)
    report.offenses.each do |offense|
      corrector.merge!(offense.corrector) if offense.corrector
    end
    corrector.process
  end

  ##============================================================##
  ## Base case: adds borders
  ##============================================================##
  def test_adds_borders_around_simple_block
    source = "## Hello world\n"

    expected = <<~RUBY
      ##============================================================##
      ## Hello world
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_keeps_existing_well_formed_block_unchanged
    source = <<~RUBY
      ##============================================================##
      ## Hello world
      ##============================================================##
    RUBY

    assert_equal(source, autocorrect(source))
  end

  def test_ignores_single_hash_comments
    source = "# regular comment\n"
    assert_equal(source, autocorrect(source))
  end

  def test_does_not_touch_inline_double_hash
    source = "x = 1 ## inline\n"
    assert_equal(source, autocorrect(source))
  end

  ##============================================================##
  ## Nettoyage des lignes
  ##============================================================##
  def test_collapses_repeated_hashes
    source = "### Hello\n"

    expected = <<~RUBY
      ##============================================================##
      ## Hello
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_collapses_extra_single_space
    source = "##  Hello\n"

    expected = <<~RUBY
      ##============================================================##
      ## Hello
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  ##============================================================##
  ## New features: content flexibility
  ##============================================================##
  def test_preserves_bullet_list
    source = <<~RUBY
      ## Liste :
      ## - item 1
      ## - item 2
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Liste :
      ## - item 1
      ## - item 2
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_preserves_nested_list_indentation
    source = <<~RUBY
      ## Liste :
      ##   - parent
      ##     - enfant
      ##   - autre
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Liste :
      ##   - parent
      ##     - enfant
      ##   - autre
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_preserves_numbered_list
    source = <<~RUBY
      ## Étapes :
      ## 1. premier
      ## 2. second
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Étapes :
      ## 1. premier
      ## 2. second
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_preserves_explicit_indentation
    source = <<~RUBY
      ## Configuration :
      ##   provider = openai
      ##   order    = 1
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Configuration :
      ##   provider = openai
      ##   order    = 1
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_preserves_pipe_raw_lines
    source = <<~RUBY
      ## Exemple :
      ## | code = brut
      ## | preserved
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Exemple :
      ## | code = brut
      ## | preserved
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_preserves_fenced_code_block
    source = <<~RUBY
      ## Exemple :
      ## ```
      ##   x = 1
      ##   y = 2
      ## ```
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Exemple :
      ## ```
      ##   x = 1
      ##   y = 2
      ## ```
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  ##============================================================##
  ## Separators and blank lines
  ##============================================================##
  def test_explicit_separator_becomes_inside_separator
    source = <<~RUBY
      ## Section A
      ## ---
      ## Section B
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Section A
      ## ---------
      ## Section B
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_keeps_blank_double_hash_line
    source = <<~RUBY
      ## Ligne 1
      ##
      ## Ligne 2
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Ligne 1
      ##
      ## Ligne 2
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_drops_leading_blank_lines
    source = <<~RUBY
      ##
      ## Premier contenu
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Premier contenu
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_empty_block_falls_back_to_placeholder
    source = "##\n"

    expected = <<~RUBY
      ##============================================================##
      ## ...
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  ##============================================================##
  ## Indentation du bloc
  ##============================================================##
  def test_respects_indentation_of_block
    source = <<~RUBY
      def foo
        ## Hello
      end
    RUBY

    expected = <<~RUBY
      def foo
        ##============================================================##
        ## Hello
        ##============================================================##
      end
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  ##============================================================##
  ## Already-formatted block with a list: must stay intact
  ## Edge cases
  ##============================================================##
  def test_unclosed_fence_keeps_content_raw_until_end
    source = <<~RUBY
      ## Exemple :
      ## ```
      ##   x = 1
      ##   y = 2
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Exemple :
      ## ```
      ##   x = 1
      ##   y = 2
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_pipe_raw_line_as_first_line
    source = <<~RUBY
      ## | premier brut
      ## | second brut
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## | premier brut
      ## | second brut
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  def test_duplicate_borders_are_collapsed
    source = <<~RUBY
      ##============================================================##
      ##============================================================##
      ## Hello
      ##============================================================##
      ##============================================================##
    RUBY

    expected = <<~RUBY
      ##============================================================##
      ## Hello
      ##============================================================##
    RUBY

    assert_equal(expected, autocorrect(source))
  end

  ##============================================================##
  ## Regression: ##---...---## section dividers and indented JSON
  ## must be preserved (was broken when Layout/LeadingCommentSpace
  ## inserted a space after the first #).
  ##============================================================##
  def test_preserves_internal_section_dividers_and_indented_json
    source = <<~RUBY
      ##============================================================##
      ## Header.
      ##   "PostToolUse": [{
      ##     "matcher": "Edit|Write",
      ##     "hooks":   [{
      ##       "type":    "command"
      ##     }]
      ##   }]
      ##
      ##------------------------------------------------------------##
      ## Section
      ##------------------------------------------------------------##
      ## body
      ##============================================================##
    RUBY

    assert_equal(source, autocorrect(source))
  end

  def test_idempotent_on_complex_block
    source = <<~RUBY
      ##============================================================##
      ## Configuration :
      ## - LRE : envoi recommandé
      ##   - avec accusé
      ##   - sans accusé
      ## - AR  : accusé
      ##
      ## ---------
      ##
      ## Exemple :
      ## ```
      ##   x = 1
      ## ```
      ##============================================================##
    RUBY

    assert_equal(source, autocorrect(source))
  end

end
