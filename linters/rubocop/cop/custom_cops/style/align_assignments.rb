module RuboCop
  module Cop
    module CustomCops
      module Style
        ##============================================================##
        ## This cop checks that consecutive assignments are aligned
        ##
        ## @example
        ## bad
        ## d2 = "xxx"
        ## variable = "yyy"
        ## very_long_variable = "zzz"
        ##
        ## good
        ## d2                 = "xxx"
        ## variable           = "yyy"
        ## very_long_variable = "zzz"
        ##============================================================##
        class AlignAssignments < Base

          extend AutoCorrector

          MSG = "Align the assignment operators of consecutive assignments.".freeze

          def on_new_investigation
            @assignment_groups    = []
            @current_group        = []
            @last_assignment_line = nil
          end

          def on_lvasgn(node)
            check_assignment(node)
          end

          def on_ivasgn(node)
            check_assignment(node)
          end

          def on_cvasgn(node)
            check_assignment(node)
          end

          def on_gvasgn(node)
            check_assignment(node)
          end

          def on_casgn(node)
            check_assignment(node)
          end

          def on_masgn(node)
            check_assignment(node)
          end

          ##============================================================##
          ## For index assignments (listing["key"] = ...)
          ##============================================================##
          def on_send(node)
            return unless node.method_name == :[]= && node.arguments.length == 2

            check_assignment(node)
          end

          def on_investigation_end
            finalize_current_group
            process_groups
          end

          private

          ##============================================================##
          ## Make sure it's a plain "=" assignment, not >=, <=, =>, etc.
          ##============================================================##
          def check_assignment(node)
            return unless assignment_operator?(node)

            add_to_group(node)
          end

          ##============================================================##
          ## Check whether the operator is a plain "=" (not >=, <=, =>, etc.)
          ##============================================================##
          def assignment_operator?(node)
            ##============================================================##
            ## For send nodes (index assignment)
            ##============================================================##
            return true if node.respond_to?(:method_name) && node.method_name == :[]=

            ##============================================================##
            ## For regular assignments
            ##============================================================##
            source = node.source.strip
            return false unless source.include?("=")

            equals_pos = source.index("=")
            return false if equals_pos > 0 && [">", "<"].include?(source[equals_pos - 1])
            return false if equals_pos < source.length - 1 && source[equals_pos + 1] == ">"

            true
          end

          ##============================================================##
          ## Add an assignment to the current group, or start a new group
          ##============================================================##
          def add_to_group(node)
            current_line = node.location.line
            if @current_group.empty?
              @current_group = [node]
            elsif consecutive_lines?(@last_assignment_line, current_line)
              @current_group << node
            else
              finalize_current_group
              @current_group = [node]
            end
            @last_assignment_line = current_line
          end

          ##============================================================##
          ## Returns true if the two lines are consecutive (no blank line between them)
          ##============================================================##
          def consecutive_lines?(line1, line2)
            gap = line2 - line1 - 1
            gap == 0
          end

          ##============================================================##
          ## Finalize the current group if it contains more than one assignment
          ##============================================================##
          def finalize_current_group
            @assignment_groups << @current_group.dup if @current_group.length > 1
            @current_group        = []
            @last_assignment_line = nil
          end

          ##============================================================##
          ## Process every assignment group to check alignment
          ##============================================================##
          def process_groups
            @assignment_groups.each do |group|
              check_and_correct_alignment(group)
            end
          end

          ##============================================================##
          ## Check a group's alignment and correct it if needed
          ##============================================================##
          def check_and_correct_alignment(group)
            lefts         = group.map {|node| node.source.split("=")[0].to_s.strip.gsub(/\s+/, "").gsub(",", ", ") }
            required_size = lefts.map(&:length).max + 1

            group.each.with_index do |node, index|
              current_source = node.source
              new_left       = lefts[index]
              new_left += " " * (required_size - new_left.length)
              split           = current_source.split("=")
              split[0]        = new_left
              expected_source = split.join("=")

              if current_source != expected_source
                add_offense(node, :message => MSG) do |corrector|
                  corrector.replace(node, expected_source)
                end
              end
            end
          end

        end
      end
    end
  end
end
