# frozen_string_literal: true

require "test-unit"
require "rubocop"
require_relative "../linters/rubocop/cop/custom_cops/style/align_routes"

class AlignRoutesTest < Test::Unit::TestCase

  ##============================================================##
  ## Runs the cop on the source and returns the corrected source
  ## along with the number of offenses found. The default path is
  ## a routes file: outside one, the cop stays out of the way.
  ##============================================================##
  def autocorrect(source, path = "config/routes.rb")
    processed    = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, path)
    cop          = RuboCop::Cop::CustomCops::Style::AlignRoutes.new(RuboCop::Config.new)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], :raise_error => true)
    report       = commissioner.investigate(processed)

    corrector = RuboCop::Cop::Corrector.new(processed)
    report.offenses.each {|o| corrector.merge!(o.corrector) if o.corrector }
    [corrector.process, report.offenses.size]
  end

  def test_aligns_verb_path_and_target
    source = <<~RUBY
      get "users" => "users#index", :as => :users
      match "users/:id" => "users#update", :via => [:patch], :as => :user
    RUBY
    expected = <<~RUBY
      get   "users"     => "users#index",                    :as => :users
      match "users/:id" => "users#update", :via => [:patch], :as => :user
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  ##============================================================##
  ## A route without `:via` leaves the column empty and its
  ## `:as` lands under the `:as` of the `match` neighbour, even
  ## though the `get` line meets `:as` first.
  ##============================================================##
  def test_via_before_as_aligns_as_under_as
    source = <<~RUBY
      get "a" => "x#a", :as => :a
      match "b" => "x#b", :via => [:get], :as => :b
    RUBY
    expected = <<~RUBY
      get   "a" => "x#a",                 :as => :a
      match "b" => "x#b", :via => [:get], :as => :b
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_to_without_positional_target_aligns_options
    source = <<~RUBY
      match "404", :to => "errors#not_found", :via => :all
      match "500", :to => "errors#internal", :via => :all
    RUBY
    expected = <<~RUBY
      match "404", :to => "errors#not_found", :via => :all
      match "500", :to => "errors#internal",  :via => :all
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_parenthesized_routes_keep_parentheses
    source = <<~RUBY
      match("form" => "landing/pages#form", :via => :post)
      match("thanks" => "landing/pages#thanks", :via => :get)
    RUBY
    expected = <<~RUBY
      match("form"   => "landing/pages#form",   :via => :post)
      match("thanks" => "landing/pages#thanks", :via => :get)
    RUBY

    out, n = autocorrect(source)
    assert_equal(1, n)
    assert_equal(expected, out)
  end

  def test_conflicting_option_orders_leave_group_unchanged
    source = <<~RUBY
      get "a" => "x#a", :as => :a, :via => :get
      get "b" => "x#b", :via => :get, :as => :b
    RUBY

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_already_aligned_is_a_noop
    source = <<~RUBY
      get   "a" => "x#a",                 :as => :a
      match "b" => "x#b", :via => [:get], :as => :b
    RUBY

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_single_route_is_a_noop
    source = "get \"a\" => \"x#a\", :as => :a\n"

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_blank_line_splits_groups
    source = <<~RUBY
      get "a" => "x#a", :as => :a

      get "longer_path" => "x#b", :as => :b
    RUBY

    out, n = autocorrect(source)
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_ignores_non_routes_files
    source = <<~RUBY
      get "a" => "x#a", :as => :a
      match "b" => "x#b", :via => [:get], :as => :b
    RUBY

    out, n = autocorrect(source, "app/services/fetcher.rb")
    assert_equal(0, n)
    assert_equal(source, out)
  end

  def test_ignores_routes_in_subdirectory_only_under_config
    source = <<~RUBY
      match "404", :to => "errors#not_found", :via => :all
      match "500", :to => "errors#internal", :via => :all
    RUBY

    _out, n = autocorrect(source, "config/routes/api.rb")
    assert_equal(1, n)
  end

end
