# frozen_string_literal: true

require "test-unit"
require "rubocop"
require_relative "../linters/rubocop/cop/custom_cops/style/kwarg_priority_order"

class KwargPriorityOrderTest < Test::Unit::TestCase

  ##============================================================##
  ## Runs the cop and returns [corrected source, offense count].
  ##============================================================##
  def autocorrect(source, methods: ["link_to"], priority_keys: ["remote", "method"])
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    cop       = RuboCop::Cop::CustomCops::Style::KwargPriorityOrder.new(
      RuboCop::Config.new(
        "CustomCops/Style/KwargPriorityOrder" => {
          "Methods"      => methods,
          "PriorityKeys" => priority_keys
        }
      )
    )
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], :raise_error => true)
    report       = commissioner.investigate(processed)

    corrector = RuboCop::Cop::Corrector.new(processed)
    report.offenses.each {|o| corrector.merge!(o.corrector) if o.corrector }
    [corrector.process, report.offenses.size]
  end

  ##============================================================##
  ## Basic promotion
  ##============================================================##
  def test_promotes_remote_to_front
    source   = "link_to(t(\"x\"), path, :class => \"x\", :remote => true)\n"
    expected = "link_to(t(\"x\"), path, :remote => true, :class => \"x\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_promotes_method_to_front
    source   = "link_to(t(\"x\"), path, :class => \"x\", :method => :delete)\n"
    expected = "link_to(t(\"x\"), path, :method => :delete, :class => \"x\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_keeps_priority_order_from_config
    source   = "link_to(t(\"x\"), path, :class => \"x\", :method => :delete, :remote => true)\n"
    expected = "link_to(t(\"x\"), path, :remote => true, :method => :delete, :class => \"x\")\n"

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## No-op cases
  ##============================================================##
  def test_does_not_touch_when_already_ordered
    source = "link_to(t(\"x\"), path, :remote => true, :class => \"x\")\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_touch_when_no_priority_kwargs
    source = "link_to(t(\"x\"), path, :class => \"x\", :data => {})\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_touch_without_kwargs
    source = "link_to(t(\"x\"), path)\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_touch_other_methods
    source = "button_to(t(\"x\"), path, :class => \"x\", :remote => true)\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_touch_braced_hash_literal
    ##============================================================##
    ## An explicit `{ :class => ..., :remote => ... }` arg is a
    ## hash literal, not implicit kwargs — leave alone.
    ##============================================================##
    source = "link_to(t(\"x\"), path, {:class => \"x\", :remote => true})\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  ##============================================================##
  ## Custom config
  ##============================================================##
  def test_custom_priority_keys
    source   = "link_to(t(\"x\"), path, :class => \"x\", :data => {:role => \"btn\"})\n"
    expected = "link_to(t(\"x\"), path, :data => {:role => \"btn\"}, :class => \"x\")\n"

    out, n = autocorrect(source, :priority_keys => ["data"])
    assert_equal(1, n)
    assert_equal(expected, out)
  end

end
