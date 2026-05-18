# frozen_string_literal: true

require "rubocop-ast"

module ERBLint
  module Linters
    ##============================================================##
    ## Aligns the arguments of consecutive ERB output calls to the
    ## same configured method (default: link_to) when:
    ##   - they're on adjacent lines,
    ##   - separated only by whitespace,
    ##   - have the same arity,
    ##   - have the same keyword keys in the same order.
    ##
    ## Each argument becomes a column; cells are right-padded with
    ## spaces so that the next argument starts at the same column
    ## across all lines in the group.
    ##
    ## @example
    ## bad
    ##   <%= link_to(t("a"), foo_path(:id => 1), :class => "dropdown-item", :remote => true) %>
    ##   <%= link_to(t("bbbb"), bar_path(:id => 2), :class => "dropdown-item #{x}", :remote => true) %>
    ##
    ## good
    ##   <%= link_to(t("a"),    foo_path(:id => 1), :class => "dropdown-item",      :remote => true) %>
    ##   <%= link_to(t("bbbb"), bar_path(:id => 2), :class => "dropdown-item #{x}", :remote => true) %>
    ##============================================================##
    class CustomAlignConsecutiveCalls < Linter

      include LinterRegistry

      MSG = "Align consecutive `%s` calls."

      class ConfigSchema < LinterConfig

        property(:methods, :accepts => array_of?(String), :default => -> { ["link_to"] })

      end

      self.config_schema = ConfigSchema

      def run(processed_source)
        output_nodes = processed_source.ast.descendants(:erb).select {|n| output_erb?(n) }
        return if output_nodes.size < 2

        ##============================================================##
        ## Group adjacent output ERB nodes (whitespace-only between).
        ##============================================================##
        groups = group_adjacent(output_nodes, processed_source)

        groups.each do |group|
          next if group.size < 2

          rebuild_group(group, processed_source)
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context[:new_code])
        end
      end

      private

      ##============================================================##
      ## Build aligned rewrites for the group, add an offense per
      ## call that needs to change.
      ##============================================================##
      def rebuild_group(group, processed_source)
        parsed = group.map {|node| parse_call(strip_code(extract_code(node))) }
        return if parsed.any?(&:nil?)

        method_name = parsed.first[:method]
        return unless allowed_methods.include?(method_name)
        return unless parsed.all? {|p| p[:method] == method_name }

        ##============================================================##
        ## All calls must share the same arg signature
        ## (same positional/kwarg layout, same kw keys in same order).
        ##============================================================##
        signatures = parsed.map {|p| p[:args].map {|a| a[:kind] == :kwarg ? [:kwarg, a[:key]] : [:positional] } }
        return unless signatures.uniq.size == 1

        n_cols     = parsed.first[:args].size
        col_widths = (0...n_cols).map {|i| parsed.map {|p| p[:args][i][:text].length }.max }

        parsed.each_with_index do |p, idx|
          rebuilt = "#{p[:method]}(#{join_padded(p[:args], col_widths)})"
          current = strip_code(extract_code(group[idx])).strip
          next if current == rebuilt

          code_loc = group[idx].children[2].loc
          range    = processed_source.to_source_range(code_loc.begin_pos...code_loc.end_pos)
          add_offense(range, format(MSG, method_name), :new_code => " #{rebuilt} ")
        end
      end

      ##============================================================##
      ## Join args with `, ` and right-pad AFTER the comma so the
      ## next column starts at a consistent position across all rows
      ## in the group. Padding goes after the comma (not before) so
      ## the comma stays glued to its arg.
      ##============================================================##
      def join_padded(args, col_widths)
        last = args.size - 1
        out  = +""
        args.each_with_index do |a, i|
          if i == last
            out << a[:text]
          else
            pad = " " * (col_widths[i] - a[:text].length)
            out << a[:text] << ", " << pad
          end
        end
        out
      end

      def allowed_methods
        Array(@config.methods)
      end

      ##============================================================##
      ## Parse a single Ruby call via the parser shipped with
      ## rubocop-ast. Returns nil if the source isn't a clean
      ## `method(args...)` call.
      ##
      ## Each hash pair is captured via `pair.loc.expression.source`
      ## so we preserve the original syntax (hashrocket vs short
      ## `key:` form). The `:key` field carries only the semantic
      ## key name (used for signature comparison across calls).
      ##
      ## Note (perf) : a `RuboCop::ProcessedSource` is created per
      ## call. For a view with hundreds of `link_to`s in a single
      ## group this scales linearly. Acceptable for the typical
      ## case (a few consecutive calls); memoise if it ever shows
      ## up in profiling.
      ##============================================================##
      def parse_call(code)
        return nil if code.nil? || code.empty?

        source = RuboCop::ProcessedSource.new(code, RUBY_VERSION.to_f)
        return nil if source.ast.nil?

        node = source.ast
        return nil unless node.respond_to?(:type) && node.type == :send
        return nil unless node.children[0].nil?

        method = node.children[1].to_s
        args   = []
        node.children[2..].each do |arg|
          if arg.type == :hash
            arg.children.each do |pair|
              key_node = pair.children.first
              args << {:kind => :kwarg, :key => key_name(key_node), :text => pair.loc.expression.source}
            end
          else
            args << {:kind => :positional, :text => arg.loc.expression.source}
          end
        end

        {:method => method, :args => args}
      rescue StandardError
        nil
      end

      ##============================================================##
      ## Extract the semantic key name from a hash pair's key node.
      ## Handles :sym (hashrocket and short syntax) and "string"
      ## keys. Dynamic keys fall back to their source.
      ##============================================================##
      def key_name(key_node)
        return nil unless key_node

        case key_node.type
        when :sym, :str then key_node.value.to_s
        else key_node.loc.expression.source
        end
      end

      ##============================================================##
      ## Walk the output nodes and break into groups whenever the
      ## text between two adjacent nodes is not whitespace-only or
      ## contains zero newlines (meaning the nodes are on the same
      ## line).
      ##============================================================##
      def group_adjacent(nodes, processed_source)
        groups  = []
        current = []
        source  = processed_source.source_buffer.source

        nodes.each do |node|
          if current.empty?
            current << node
            next
          end

          between = source[current.last.loc.end_pos...node.loc.begin_pos]
          if between.match?(/\A\s*\z/) && between.count("\n") >= 1
            current << node
          else
            groups << current
            current = [node]
          end
        end

        groups << current unless current.empty?
        groups
      end

      def output_erb?(erb_node)
        indicator = erb_node.children.first
        indicator.respond_to?(:children) && indicator.children.first == "="
      end

      def extract_code(erb_node)
        erb_node.children[2]&.loc&.source
      end

      def strip_code(code)
        code.to_s.strip
      end

    end
  end
end
