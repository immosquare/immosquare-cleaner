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
            @assignment_groups = []
            find_assignment_groups
          end

          def on_lvasgn(node)
            check_alignment(node)
          end

          def on_casgn(node)
            check_alignment(node)
          end

          def on_ivasgn(node)
            check_alignment(node)
          end

          def on_cvasgn(node)
            check_alignment(node)
          end

          def on_gvasgn(node)
            check_alignment(node)
          end

          private

          def find_assignment_groups
            assignment_lines = {}

            processed_source.ast.each_node do |node|
              next unless assignment_node?(node)

              line = node.source_range.line
              assignment_lines[line] = node
            end

            current_group = []
            previous_line = nil

            assignment_lines.keys.sort.each do |line|
              if previous_line && consecutive_lines?(previous_line, line)
                ##============================================================##
                ## Consecutive line (no empty line between the two)
                ##============================================================##
                current_group << assignment_lines[line] if current_group.empty?
                current_group << assignment_lines[line] unless current_group.include?(assignment_lines[line])
              else
                ##============================================================##
                ## New sequence (empty line or gap)
                ##============================================================##
                @assignment_groups << current_group if current_group.size > 1
                current_group = [assignment_lines[line]]
              end
              previous_line = line
            end

            @assignment_groups << current_group if current_group.size > 1
          end

          def consecutive_lines?(line1, line2)
            ##============================================================##
            ## If line2 is just after line1, they are consecutive
            ##============================================================##
            return true if line2 == line1 + 1

            ##============================================================##
            ## If there are lines between line1 and line2, they are not consecutive
            ## (even if these lines are empty)
            ##============================================================##
            false
          end

          def check_alignment(node)
            group = @assignment_groups.find {|g| g.include?(node) }
            return unless group

            ##============================================================##
            ## Calculate the minimum column needed to align all assignments
            ##============================================================##
            min_alignment_column = calculate_min_alignment_column(group)

            current_column = assignment_operator_column(node)
            return if current_column == min_alignment_column

            ##============================================================##
            ## Ensure that spaces_needed is not negative
            ##============================================================##
            spaces_needed = [min_alignment_column - current_column, 0].max

            add_offense(
              node.source_range,
              :message => MSG
            ) do |corrector|
              assignment_range = assignment_operator_range(node)
              corrector.insert_before(assignment_range, " " * spaces_needed)
            end
          end

          def calculate_min_alignment_column(group)
            ##============================================================##
            ## For each assignment, calculate the minimum column needed
            ## based on the variable name length + 1 space
            ##============================================================##
            max_variable_length = group.map do |node|
              variable_name_length(node)
            end.max

            ##============================================================##
            ## The minimum column is the max length + 1 space + the base indentation
            ##============================================================##
            base_indentation = group.first.source_range.column
            base_indentation + max_variable_length + 1
          end

          def variable_name_length(node)
            case node.type
            when :lvasgn, :ivasgn, :cvasgn, :gvasgn
              node.children[0].to_s.length
            when :casgn
              if node.children[0] # namespace
                node.children[0].source.length + 2 + node.children[1].to_s.length # + '::'
              else
                node.children[1].to_s.length
              end
            end
          end

          def assignment_node?(node)
            [:lvasgn, :casgn, :ivasgn, :cvasgn, :gvasgn].include?(node.type)
          end

          def assignment_operator_column(node)
            assignment_operator_range(node).column
          end

          def assignment_operator_range(node)
            source    = processed_source.buffer.source
            start_pos = node.source_range.begin_pos
            end_pos   = node.source_range.end_pos

            # Chercher le premier = dans la ligne
            (start_pos...end_pos).each do |pos|
              return range(processed_source.buffer, pos, pos + 1) if source[pos] == "="
            end

            ##============================================================##
            ## Fallback if no = is found
            ##============================================================##
            range(processed_source.buffer, start_pos, start_pos + 1)
          end

          def range(buffer, start_pos, end_pos)
            Parser::Source::Range.new(buffer, start_pos, end_pos)
          end


        end
      end
    end
  end
end
