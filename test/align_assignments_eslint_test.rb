# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

##============================================================##
## End-to-end tests for the align-assignments ESLint rule
## (linters/eslint-plugins/align-assignments.mjs), run through
## the real ImmosquareCleaner.clean path so that .js.erb files
## also go through eslint-plugin-erb's placeholder mapping.
##============================================================##
class AlignAssignmentsEslintTest < Test::Unit::TestCase

  def setup
    @tmp_dir = "test/tmp_align_assignments_eslint_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  def clean(basename, source)
    file_path = File.join(@tmp_dir, basename)
    File.write(file_path, source)
    ImmosquareCleaner.clean(file_path)
    File.read(file_path)
  end

  ##============================================================##
  ## eslint-plugin-erb replaces `<%= %>` with a placeholder whose
  ## AST node ends inside the marker. A fix whose range ends at
  ## that node boundary is mapped back incorrectly and replaces
  ## the ERB tag with a fragment of the placeholder. The rule must
  ## only rewrite the spacing before the operator.
  ##============================================================##
  def test_js_erb_keeps_erb_tag_ending_the_last_assignment_of_a_group
    content = clean("sample.js.erb", <<~JS)
      const modalContainer = document.querySelector("#modal")
      modalContainer.dataset.label = "<%= j(@resource.name) %>"
      modalContainer.dataset.id = <%= @resource.id %>
    JS

    expected = <<~JS
      const modalContainer         = document.querySelector("#modal")
      modalContainer.dataset.label = "<%= j(@resource.name) %>"
      modalContainer.dataset.id    = <%= @resource.id %>
    JS

    assert_equal(expected, content)
  end

  ##============================================================##
  ## Logical assignment operators are wider than `=`: their last
  ## character is aligned with the `=` of the other lines. If they
  ## are not recognized, the autofix never converges.
  ##============================================================##
  def test_aligns_logical_assignment_operators_with_plain_assignments
    content = clean("logical.js", <<~JS)
      let x = 1
      let longName = 2
      x ||= 3
      longName ??= 4
      console.log(x, longName)
    JS

    expected = <<~JS
      let x        = 1
      let longName = 2
      x          ||= 3
      longName   ??= 4
      console.log(x, longName)
    JS

    assert_equal(expected, content)
  end

  ##============================================================##
  ## The fix replaces the gap between the left side and the
  ## operator: a comment in that gap must not be erased.
  ##============================================================##
  def test_keeps_comment_between_left_side_and_operator
    content = clean("comment.js", <<~JS)
      let x = 1
      let longName /* unit: px */ = 2
      console.log(x, longName)
    JS

    expected = <<~JS
      let x                       = 1
      let longName /* unit: px */ = 2
      console.log(x, longName)
    JS

    assert_equal(expected, content)
  end

end
