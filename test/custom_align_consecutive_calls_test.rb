# frozen_string_literal: true

require "test-unit"
require "erb_lint/all"
require "better_html"
require "better_html/parser"
require_relative "../linters/erb_lint/custom_align_consecutive_calls"

class CustomAlignConsecutiveCallsTest < Test::Unit::TestCase

  ##============================================================##
  ## Autocorrect helper — runs the linter on the given ERB source
  ## and returns the corrected content.
  ##============================================================##
  def autocorrect(source, methods: ["link_to"])
    processed_source = ERBLint::ProcessedSource.new("test.html.erb", source)
    schema           = ERBLint::Linters::CustomAlignConsecutiveCalls::ConfigSchema.new(:methods => methods)
    linter           = ERBLint::Linters::CustomAlignConsecutiveCalls.new(nil, schema)

    linter.run(processed_source)
    corrector = ERBLint::Corrector.new(processed_source, linter.offenses)
    [corrector.corrected_content, linter.offenses.size]
  end

  ##============================================================##
  ## Two consecutive link_to with identical kwarg keys → padding
  ## is applied so that the next column starts at the same position
  ## across both lines.
  ##============================================================##
  def test_aligns_two_consecutive_link_to_calls
    source = <<~ERB
      <%= link_to(t("a"), foo_path(:id => 1), :class => "dropdown-item", :remote => true) %>
      <%= link_to(t("bbbb"), bar_path(:id => 2), :class => "dropdown-item #\{x}", :remote => true) %>
    ERB

    expected = <<~ERB
      <%= link_to(t("a"),    foo_path(:id => 1), :class => "dropdown-item",      :remote => true) %>
      <%= link_to(t("bbbb"), bar_path(:id => 2), :class => "dropdown-item #\{x}", :remote => true) %>
    ERB

    out, n = autocorrect(source)
    assert_operator(n, :>=, 1, "expected at least one offense")
    assert_equal(expected, out)
  end

  ##============================================================##
  ## Single call — nothing to align.
  ##============================================================##
  def test_single_call_unchanged
    source = %(<%= link_to(t("a"), foo_path(:id => 1), :class => "x") %>\n)
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Different kwarg signatures must NOT be aligned.
  ##============================================================##
  def test_different_kwarg_keys_not_aligned
    source = <<~ERB
      <%= link_to(t("a"), foo_path, :class => "x", :remote => true) %>
      <%= link_to(t("bbbb"), bar_path, :class => "y", :data => {}) %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Different arity must NOT be aligned.
  ##============================================================##
  def test_different_arity_not_aligned
    source = <<~ERB
      <%= link_to(t("a"), foo_path) %>
      <%= link_to(t("bbbb"), bar_path, :class => "x") %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Calls separated by other markup → not adjacent → not aligned.
  ##============================================================##
  def test_calls_with_html_between_not_aligned
    source = <<~ERB
      <%= link_to(t("a"), foo_path(:id => 1), :class => "x", :remote => true) %>
      <span>separator</span>
      <%= link_to(t("bbbb"), bar_path(:id => 2), :class => "y", :remote => true) %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Method not in allowlist → ignored.
  ##============================================================##
  def test_method_not_in_allowlist_ignored
    source = <<~ERB
      <%= button_to(t("a"), foo_path, :class => "x") %>
      <%= button_to(t("bbbb"), bar_path, :class => "y") %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Short hash syntax (`key:`) must be preserved verbatim, not
  ## rewritten as `key =>` (which would be invalid Ruby).
  ##============================================================##
  def test_preserves_short_hash_syntax
    source = <<~ERB
      <%= link_to(t("a"), foo_path, class: "x", remote: true) %>
      <%= link_to(t("bbbb"), bar_path, class: "y", remote: true) %>
    ERB

    expected = <<~ERB
      <%= link_to(t("a"),    foo_path, class: "x", remote: true) %>
      <%= link_to(t("bbbb"), bar_path, class: "y", remote: true) %>
    ERB

    out, n = autocorrect(source)
    assert_operator(n, :>=, 1, "expected at least one offense")
    assert_equal(expected, out)
  end

  ##============================================================##
  ## Mixed syntax (hashrocket on one line, short on another) with
  ## the same semantic keys must still align without corrupting
  ## either line's syntax.
  ##============================================================##
  def test_mixed_hash_syntaxes_keep_each_line_syntax
    source = <<~ERB
      <%= link_to(t("a"), foo_path, :class => "x", :remote => true) %>
      <%= link_to(t("bbbb"), bar_path, class: "y", remote: true) %>
    ERB

    out, = autocorrect(source)
    assert_match(/:class => "x"/, out, "hashrocket line must keep hashrocket syntax")
    assert_match(/class: "y"/, out, "short syntax line must keep short syntax")
    refute_match(/class => "y"/, out, "short syntax must not be corrupted to `class => ...`")
  end

  ##============================================================##
  ## Configurable method allowlist — explicit opt-in for button_to.
  ##============================================================##
  def test_supports_custom_methods_config
    source = <<~ERB
      <%= button_to(t("a"), foo_path, :class => "x") %>
      <%= button_to(t("bbbb"), bar_path, :class => "y") %>
    ERB

    expected = <<~ERB
      <%= button_to(t("a"),    foo_path, :class => "x") %>
      <%= button_to(t("bbbb"), bar_path, :class => "y") %>
    ERB

    out, n = autocorrect(source, :methods => ["button_to"])
    assert_operator(n, :>=, 1, "expected at least one offense")
    assert_equal(expected, out)
  end

end
