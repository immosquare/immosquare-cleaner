# frozen_string_literal: true

##============================================================##
## Custom erb_lint linters are stored in this folder.
## A symlink .erb_linters -> linters/erb_lint is required at the
## gem root because erb_lint hardcodes the custom linters directory
## to ".erb_linters" and this cannot be configured.
## See: https://github.com/Shopify/erb_lint/blob/main/lib/erb_lint/linter_registry.rb#L7
##============================================================##

module ERBLint
  module Linters
    ##============================================================##
    ## This linter detects if/unless blocks with a single ERB output
    ## statement and converts them to inline modifier syntax.
    ##
    ## @example
    ##   # bad
    ##   <% if condition %>
    ##     <%= link_to("Home", root_path) %>
    ##   <% end %>
    ##
    ##   # good
    ##   <%= link_to("Home", root_path) if condition %>
    ##
    ##============================================================##
    class CustomSingleLineIfModifier < Linter
      include LinterRegistry

      MSG = "Use modifier if/unless for single-line ERB output."

      def run(processed_source)
        erb_nodes = processed_source.ast.descendants(:erb).to_a
        return if erb_nodes.size < 3

        erb_nodes.each_with_index do |erb_node, index|
          ##============================================================##
          ## We need at least 3 consecutive ERB nodes:
          ## 1. <% if/unless condition %>
          ## 2. <%= output %>
          ## 3. <% end %>
          ##============================================================##
          next if index + 2 >= erb_nodes.size

          if_node     = erb_node
          output_node = erb_nodes[index + 1]
          end_node    = erb_nodes[index + 2]

          ##============================================================##
          ## Check if this is a valid pattern to transform
          ##============================================================##
          next unless valid_if_modifier_pattern?(if_node, output_node, end_node, processed_source)

          ##============================================================##
          ## Extract the condition and output code
          ##============================================================##
          if_code     = extract_code(if_node)
          output_code = extract_code(output_node)

          condition_match = if_code.match(/\A\s*(if|unless)\s+(.+)\s*\z/m)
          next unless condition_match

          keyword   = condition_match[1]
          condition = condition_match[2].strip

          ##============================================================##
          ## Build the new inline syntax
          ##============================================================##
          new_code = "#{output_code.strip} #{keyword} #{condition}"

          ##============================================================##
          ## Calculate the full range from if to end (inclusive)
          ##============================================================##
          full_range = processed_source.to_source_range(
            if_node.loc.begin_pos...end_node.loc.end_pos
          )

          ##============================================================##
          ## Store context for autocorrect
          ##============================================================##
          context = {
            :new_code       => "<%= #{new_code} %>",
            :output_node    => output_node,
            :is_output_node => is_output_erb?(output_node)
          }

          add_offense(full_range, MSG, context)
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context[:new_code])
        end
      end

      private

      ##============================================================##
      ## Check if this is a valid pattern:
      ## - First node is <% if/unless condition %>
      ## - Second node is <%= output %> (output ERB)
      ## - Third node is <% end %>
      ## - No other ERB nodes between them
      ##============================================================##
      def valid_if_modifier_pattern?(if_node, output_node, end_node, processed_source)
        ##============================================================##
        ## Check indicators: if_node should be <% (not <%=)
        ##                   output_node should be <%= (output)
        ##                   end_node should be <% (not <%=)
        ##============================================================##
        return false unless is_statement_erb?(if_node)
        return false unless is_output_erb?(output_node)
        return false unless is_statement_erb?(end_node)

        ##============================================================##
        ## Extract and validate the code
        ##============================================================##
        if_code     = extract_code(if_node)
        output_code = extract_code(output_node)
        end_code    = extract_code(end_node)

        return false unless if_code&.match?(/\A\s*(if|unless)\s+.+\z/m)
        return false unless end_code&.strip == "end"
        return false if output_code.to_s.strip.empty?

        ##============================================================##
        ## Check that there's only whitespace/newlines between the nodes
        ## (no other HTML content or ERB nodes)
        ##============================================================##
        between_if_and_output = source_between(processed_source, if_node, output_node)
        between_output_and_end = source_between(processed_source, output_node, end_node)

        return false unless between_if_and_output&.match?(/\A\s*\z/)
        return false unless between_output_and_end&.match?(/\A\s*\z/)

        true
      end

      ##============================================================##
      ## Check if ERB node is a statement (<% ... %>)
      ##============================================================##
      def is_statement_erb?(erb_node)
        indicator = erb_node.children.first
        indicator.nil? || (indicator.respond_to?(:children) && indicator.children.first.nil?)
      end

      ##============================================================##
      ## Check if ERB node is an output (<%= ... %>)
      ##============================================================##
      def is_output_erb?(erb_node)
        indicator = erb_node.children.first
        indicator&.respond_to?(:children) && indicator.children.first == "="
      end

      ##============================================================##
      ## Extract the Ruby code from an ERB node
      ##============================================================##
      def extract_code(erb_node)
        code_node = erb_node.children[2]
        return nil unless code_node

        code_node.loc.source
      end

      ##============================================================##
      ## Get the source text between two nodes
      ##============================================================##
      def source_between(processed_source, node1, node2)
        start_pos = node1.loc.end_pos
        end_pos   = node2.loc.begin_pos
        return "" if start_pos >= end_pos

        processed_source.source_buffer.source[start_pos...end_pos]
      end
    end
  end
end
