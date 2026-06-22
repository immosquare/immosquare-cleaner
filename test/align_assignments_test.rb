# frozen_string_literal: true

require "test-unit"
require "rubocop"
require_relative "../linters/rubocop/cop/custom_cops/style/align_assignments"

class AlignAssignmentsTest < Test::Unit::TestCase

  ##============================================================##
  ## Runs the cop on the source and returns the corrected source
  ## along with the number of offenses found.
  ##============================================================##
  def autocorrect(source)
    processed    = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    cop          = RuboCop::Cop::CustomCops::Style::AlignAssignments.new(RuboCop::Config.new)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], :raise_error => true)
    report       = commissioner.investigate(processed)

    corrector = RuboCop::Cop::Corrector.new(processed)
    report.offenses.each {|o| corrector.merge!(o.corrector) if o.corrector }
    [corrector.process, report.offenses.size]
  end

  ##============================================================##
  ## Aligning consecutive assignments
  ##============================================================##
  def test_aligns_three_consecutive_assignments
    source = <<~RUBY
      a = 1
      bb = 2
      ccc = 3
    RUBY
    expected = <<~RUBY
      a   = 1
      bb  = 2
      ccc = 3
    RUBY

    out, n = autocorrect(source)
    assert_equal(2, n)
    assert_equal(expected, out)
  end

  def test_aligns_consecutive_instance_variables
    source = <<~RUBY
      @a = 1
      @bb = 2
    RUBY
    expected = <<~RUBY
      @a  = 1
      @bb = 2
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## No-op cases
  ##============================================================##
  def test_does_not_touch_single_assignment
    source = "a = 1\n"
    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_blank_line_splits_groups
    source = <<~RUBY
      a = 1

      bbbb = 2
    RUBY

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_does_not_mistake_hash_rocket_for_assignment
    source = <<~RUBY
      h = {:a => 1}
      bb = 2
    RUBY
    expected = <<~RUBY
      h  = {:a => 1}
      bb = 2
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

end
