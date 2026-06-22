# frozen_string_literal: true

require "test-unit"
require "erb_lint/all"
require "better_html"
require "better_html/parser"
require_relative "../linters/erb_lint/custom_single_line_if_modifier"

class CustomSingleLineIfModifierTest < Test::Unit::TestCase

  ##============================================================##
  ## Autocorrect helper — runs the linter on the given ERB source
  ## and returns the corrected content plus the offense count.
  ##============================================================##
  def autocorrect(source)
    processed_source = ERBLint::ProcessedSource.new("test.html.erb", source)
    linter           = ERBLint::Linters::CustomSingleLineIfModifier.new(nil, ERBLint::LinterConfig.new)

    linter.run(processed_source)
    corrector = ERBLint::Corrector.new(processed_source, linter.offenses)
    [corrector.corrected_content, linter.offenses.size]
  end

  ##============================================================##
  ## if-form: <% if %> / <%= output %> / <% end %> collapses to a
  ## single <%= output if condition %> modifier line.
  ##============================================================##
  def test_if_form_collapses_to_modifier
    source = <<~ERB
      <% if condition %>
        <%=  link_to("Home", root_path) %>
      <% end %>
    ERB

    expected = %(<%= link_to("Home", root_path) if condition %>\n)

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## unless-form collapses similarly to a modifier line.
  ##============================================================##
  def test_unless_form_collapses_to_modifier
    source = <<~ERB
      <% unless condition %>
        <%= link_to("Home", root_path) %>
      <% end %>
    ERB

    expected = %(<%= link_to("Home", root_path) unless condition %>\n)

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## HTML content between the if and the output prevents the
  ## transform (only whitespace is allowed between the nodes).
  ##============================================================##
  def test_html_between_is_noop
    source = <<~ERB
      <% if condition %>
        <span>x</span>
        <%= link_to("Home", root_path) %>
      <% end %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## A statement middle node (<% ... %>) rather than an output
  ## (<%= ... %>) prevents the transform.
  ##============================================================##
  def test_statement_middle_node_is_noop
    source = <<~ERB
      <% if x %>
        <% foo %>
      <% end %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Fewer than 3 erb nodes — the linter returns early.
  ##============================================================##
  def test_fewer_than_three_erb_nodes_is_noop
    source = <<~ERB
      <% if x %>
        <%= bar %>
    ERB

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

end
