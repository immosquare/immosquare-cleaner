# frozen_string_literal: true

require "test-unit"
require "rubocop"
require_relative "../linters/rubocop/cop/custom_cops/style/font_awesome_normalization"

class FontAwesomeNormalizationTest < Test::Unit::TestCase

  ##============================================================##
  ## Runs the cop on the source and returns the corrected source
  ## along with the number of offenses found.
  ##============================================================##
  def autocorrect(source)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    cop       = RuboCop::Cop::CustomCops::Style::FontAwesomeNormalization.new(RuboCop::Config.new)

    commissioner = RuboCop::Cop::Commissioner.new([cop], [], :raise_error => true)
    report       = commissioner.investigate(processed)

    corrector = RuboCop::Cop::Corrector.new(processed)
    report.offenses.each {|o| corrector.merge!(o.corrector) if o.corrector }
    [corrector.process, report.offenses.size]
  end

  ##============================================================##
  ## Short single-letter prefixes -> long versions
  ##============================================================##
  def test_rewrites_fas_to_fa_solid
    source   = "font_awesome_icon(\"fas fa-user\")\n"
    expected = "font_awesome_icon(\"fa-solid fa-user\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_rewrites_far_to_fa_regular
    source   = "font_awesome_icon(\"far fa-circle-info\")\n"
    expected = "font_awesome_icon(\"fa-regular fa-circle-info\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_rewrites_fab_to_fa_brands
    source   = "font_awesome_icon(\"fab fa-github\")\n"
    expected = "font_awesome_icon(\"fa-brands fa-github\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## Multi-letter prefix -> compound long version
  ##============================================================##
  def test_rewrites_fass_to_fa_sharp_solid
    source   = "font_awesome_icon(\"fass fa-user\")\n"
    expected = "font_awesome_icon(\"fa-sharp fa-solid fa-user\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## Interpolated strings (dstr nodes)
  ##============================================================##
  def test_rewrites_prefix_in_interpolated_string
    source   = "font_awesome_icon(\"fal fa-\#{icon}\")\n"
    expected = "font_awesome_icon(\"fa-light fa-\#{icon}\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## No-op cases
  ##============================================================##
  def test_does_not_touch_already_long_prefix
    source = "font_awesome_icon(\"fa-solid fa-user\")\n"

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_touch_string_without_fa_prefix
    source = "font_awesome_icon(\"just a plain string\")\n"

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_ignores_other_helper_methods
    source = "some_other_helper(\"fas fa-user\")\n"

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

end
