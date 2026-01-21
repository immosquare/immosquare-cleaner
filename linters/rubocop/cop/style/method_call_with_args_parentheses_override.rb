module RuboCop
  module Cop
    module Style
      class MethodCallWithArgsParentheses

        module RequireParentheses
          private

          ##============================================================##
          ## https://github.com/rubocop/rubocop/blob/master/lib/rubocop/cop/style/method_call_with_args_parentheses/require_parentheses.rb#L31
          ## --
          ##
          ## We override this method to allow for the omission of parentheses
          ## for a new custom case "jbuider_style?"...
          ##
          ## ---Jbuilder block Example---
          ##
          ## Jbuilder.encode do |myjson|
          ##   myjson.first_name  "Jhon"
          ##   myjson.last_name   "Doe"
          ##   myjson.id          12
          ## end
          ##
          ## ---- Jbuilder file Example  ---
          ## json.first_name  "Jhon"
          ## json.last_name   "Doe"
          ## json.id          12
          ##============================================================##
          def eligible_for_parentheses_omission?(node)
            node.operator_method? || node.setter_method? || ignored_macro?(node) || jbuider_style?(node)
          end

          def jbuider_style?(node)
            receiver, method_name = *node
            return false unless receiver

            ##============================================================##
            ## Check if the node is in a Jbuilder block
            ##============================================================##
            jbuilder_block_node = node.each_ancestor(:block).find do |ancestor_node|
              block_method_name = ancestor_node.children.first.method_name
              (block_method_name == :encode || block_method_name == :new) && ancestor_node.children.first.receiver&.const_name == "Jbuilder"
            end

            ##============================================================##
            ## Source Name is the name of the method called. Here in our
            ## block it will be "json" but it can be any value put in the
            ## Jbuilder.encode do |name|
            ## ----
            ## In .json.jbuilder files, it will always be "json"
            ##============================================================##
            source_name   = receiver.loc.expression.source
            jbuilder_file = node.source_range.source_buffer.name.end_with?(".jbuilder")


            (jbuilder_block_node || (source_name == "json" && jbuilder_file)) && !method_name.to_s.end_with?("=")
          end
        end

      end
    end
  end
end
