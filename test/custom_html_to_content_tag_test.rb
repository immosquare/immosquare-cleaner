# frozen_string_literal: true

require_relative "test_helper"

class CustomHtmlToContentTagTest < Test::Unit::TestCase

  include TestHelper

  ##============================================================##
  ## Basic conversions
  ##============================================================##

  def test_simple_tag_with_erb
    source = '<div class="card"><%= t("title") %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, t("title"), :class => "card") %>', result)
  end

  def test_tag_without_attributes
    source = "<span><%= @name %></span>"
    result = autocorrect(source)
    assert_equal("<%= content_tag(:span, @name) %>", result)
  end

  def test_multiple_attributes
    source = '<div class="foo" id="bar"><%= content %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, content, :class => "foo", :id => "bar") %>', result)
  end

  ##============================================================##
  ## Data attributes
  ##============================================================##

  def test_data_attributes
    source = '<div data-controller="modal"><%= content %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, content, :"data-controller" => "modal") %>', result)
  end

  def test_data_attribute_with_json_double_quotes
    source = %(<div data-config='["a", "b"]'><%= content %></div>)
    result = autocorrect(source)
    assert_equal(%(<%= content_tag(:div, content, :"data-config" => '["a", "b"]') %>), result)
  end

  ##============================================================##
  ## ERB in attributes
  ##============================================================##

  def test_pure_erb_attribute
    source = '<div class="<%= "active" if @active %>"><%= content %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, content, :class => ("active" if @active)) %>', result)
  end

  def test_mixed_erb_attribute
    source = '<div class="btn <%= @style %>"><%= content %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, content, :class => "btn #{@style}") %>', result)
  end

  ##============================================================##
  ## If/unless modifiers in content
  ##============================================================##

  def test_if_modifier_moved_outside
    source = '<div class="mb"><%= value if value.present? %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, value, :class => "mb") if value.present? %>', result)
  end

  def test_unless_modifier_moved_outside
    source = "<span><%= @error unless @valid %></span>"
    result = autocorrect(source)
    assert_equal("<%= content_tag(:span, @error) unless @valid %>", result)
  end

  ##============================================================##
  ## Method calls needing parentheses
  ##============================================================##

  def test_method_call_without_parens_wrapped
    source = '<div class="x"><%= tag t("add"), path, :class => "btn" %></div>'
    result = autocorrect(source)
    assert_equal('<%= content_tag(:div, (tag t("add"), path, :class => "btn"), :class => "x") %>', result)
  end

  def test_method_call_with_parens_not_wrapped
    source = '<div><%= link_to("text", path) %></div>'
    result = autocorrect(source)
    # link_to is excluded, so no conversion
    assert_equal('<div><%= link_to("text", path) %></div>', result)
  end

  ##============================================================##
  ## Custom tag names (with hyphens)
  ##============================================================##

  def test_custom_tag_with_hyphen
    source = "<x-card><%= content %></x-card>"
    result = autocorrect(source)
    assert_equal('<%= content_tag("x-card", content) %>', result)
  end

  def test_custom_tag_with_class
    source = '<my-component class="styled"><%= content %></my-component>'
    result = autocorrect(source)
    assert_equal('<%= content_tag("my-component", content, :class => "styled") %>', result)
  end

  ##============================================================##
  ## Excluded methods
  ##============================================================##

  def test_yield_not_converted
    source = '<div class="container"><%= yield %></div>'
    result = autocorrect(source)
    assert_equal('<div class="container"><%= yield %></div>', result)
  end

  def test_render_not_converted
    source = '<div><%= render "partial" %></div>'
    result = autocorrect(source)
    assert_equal('<div><%= render "partial" %></div>', result)
  end

  def test_content_tag_not_converted
    source = '<div><%= content_tag(:span, "text") %></div>'
    result = autocorrect(source)
    assert_equal('<div><%= content_tag(:span, "text") %></div>', result)
  end

  def test_link_to_not_converted
    source = '<div><%= link_to "Home", root_path %></div>'
    result = autocorrect(source)
    assert_equal('<div><%= link_to "Home", root_path %></div>', result)
  end

  def test_image_tag_not_converted
    source = '<div><%= image_tag "logo.png" %></div>'
    result = autocorrect(source)
    assert_equal('<div><%= image_tag "logo.png" %></div>', result)
  end

  ##============================================================##
  ## Form builder methods
  ##============================================================##

  def test_form_builder_input_not_converted
    source = "<div><%= f.input :name %></div>"
    result = autocorrect(source)
    assert_equal("<div><%= f.input :name %></div>", result)
  end

  def test_form_builder_text_field_not_converted
    source = "<div><%= form.text_field :email %></div>"
    result = autocorrect(source)
    assert_equal("<div><%= form.text_field :email %></div>", result)
  end

  ##============================================================##
  ## Nested tags - only innermost converted
  ##============================================================##

  def test_nested_tags_only_innermost_converted
    source = <<~ERB.chomp
      <div class="container">
        <div class="row">
          <%= t("hello") %>
        </div>
      </div>
    ERB

    result = autocorrect(source)

    expected = <<~ERB.chomp
      <div class="container">
        <%= content_tag(:div, t("hello"), :class => "row") %>
      </div>
    ERB

    assert_equal(expected, result)
  end

  def test_deeply_nested_tags_only_innermost_converted
    source = <<~ERB.chomp
      <div class="a">
        <div class="b">
          <div class="c">
            <%= content %>
          </div>
        </div>
      </div>
    ERB

    result = autocorrect(source)

    expected = <<~ERB.chomp
      <div class="a">
        <div class="b">
          <%= content_tag(:div, content, :class => "c") %>
        </div>
      </div>
    ERB

    assert_equal(expected, result)
  end

  ##============================================================##
  ## Excluded HTML tags
  ##============================================================##

  def test_table_tags_not_converted
    source = "<td><%= @value %></td>"
    result = autocorrect(source)
    assert_equal("<td><%= @value %></td>", result)
  end

  def test_tr_not_converted
    source = "<tr><%= content %></tr>"
    result = autocorrect(source)
    assert_equal("<tr><%= content %></tr>", result)
  end

  ##============================================================##
  ## Edge cases
  ##============================================================##

  def test_tag_with_text_and_erb_not_converted
    source = "<div>Hello <%= @name %></div>"
    result = autocorrect(source)
    assert_equal("<div>Hello <%= @name %></div>", result)
  end

  def test_tag_with_multiple_erb_not_converted
    source = "<div><%= @first %> <%= @last %></div>"
    result = autocorrect(source)
    assert_equal("<div><%= @first %> <%= @last %></div>", result)
  end

  def test_erb_statement_not_converted
    source = "<div><% do_something %></div>"
    result = autocorrect(source)
    assert_equal("<div><% do_something %></div>", result)
  end

  def test_void_elements_not_converted
    source = "<input><%= @value %></input>"
    offenses = run_linter(source)
    assert_true(offenses.empty?)
  end

  def test_self_closing_tag_not_matched
    source = "<br /><%= content %>"
    offenses = run_linter(source)
    assert_true(offenses.empty?)
  end

end
