# frozen_string_literal: true

require "test-unit"
require "rubocop"
require_relative "../linters/rubocop/cop/custom_cops/style/inline_multiline_calls"

class InlineMultilineCallsTest < Test::Unit::TestCase

  ##============================================================##
  ## Runs the cop on the source and returns the corrected source
  ## along with the number of offenses found.
  ##============================================================##
  def autocorrect(source, methods: ["link_to"])
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    cop       = RuboCop::Cop::CustomCops::Style::InlineMultilineCalls.new(
      RuboCop::Config.new("CustomCops/Style/InlineMultilineCalls" => {"Methods" => methods})
    )
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], :raise_error => true)
    report       = commissioner.investigate(processed)

    corrector = RuboCop::Cop::Corrector.new(processed)
    report.offenses.each {|o| corrector.merge!(o.corrector) if o.corrector }
    [corrector.process, report.offenses.size]
  end

  ##============================================================##
  ## Basic collapse
  ##============================================================##
  def test_collapses_basic_multiline_link_to
    source = <<~RUBY
      link_to(t("foo"),
              path,
              :class => "x")
    RUBY
    expected = "link_to(t(\"foo\"), path, :class => \"x\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_collapses_with_hashrocket_kwargs
    source = <<~RUBY
      link_to(t("app.add.x"),
              some_path(:id => 1),
              :class  => "dropdown-item",
              :remote => true)
    RUBY
    expected = "link_to(t(\"app.add.x\"), some_path(:id => 1), :class  => \"dropdown-item\", :remote => true)\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## No-op cases
  ##============================================================##
  def test_does_not_touch_single_line_call
    source = "link_to(t(\"foo\"), path, :class => \"x\")\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_touch_other_methods_when_not_in_allowlist
    source = <<~RUBY
      content_tag(:div,
                  "x")
    RUBY
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Safety: refuse to act when collapsing would corrupt code
  ##============================================================##
  def test_skips_when_comment_inside_call
    source = <<~RUBY
      link_to(label,
              path, # important: keep this commented
              :class => "x")
    RUBY

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_preserves_internal_whitespace_in_strings
    source = <<~RUBY
      link_to("Click   here",
              path,
              :class => "x")
    RUBY
    expected = "link_to(\"Click   here\", path, :class => \"x\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_skips_when_string_literal_spans_multiple_lines
    source = <<~RUBY
      link_to("line1
      line2",
              path)
    RUBY

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Config-driven allowlist
  ##============================================================##
  def test_supports_custom_methods_config
    source = <<~RUBY
      button_to(t("foo"),
                path)
    RUBY
    expected = "button_to(t(\"foo\"), path)\n"

    out, n = autocorrect(source, :methods => ["link_to", "button_to"])
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_block_form_keeps_block_intact
    source = <<~RUBY
      link_to(
        "/foo",
        :class => "x"
      ) do
        "content"
      end
    RUBY
    expected = <<~RUBY
      link_to("/foo", :class => "x") do
        "content"
      end
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

end
