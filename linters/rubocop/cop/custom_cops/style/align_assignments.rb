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

          MSG              = "Align the assignment operators of consecutive assignments.".freeze
          ASSIGNMENT_TYPES = [:lvasgn, :casgn, :ivasgn, :cvasgn, :gvasgn].freeze

          def on_new_investigation
            @assignment_groups = find_assignment_groups
          end

          ASSIGNMENT_TYPES.each do |type|
            define_method(:"on_#{type}") do |node|
              check_alignment(node)
            end
          end

          private

          def find_assignment_groups
            assignments_by_line = {}

            processed_source.ast.each_node do |node|
              next unless ASSIGNMENT_TYPES.include?(node.type)

              assignments_by_line[node.source_range.line] = node
            end

            group_consecutive_assignments(assignments_by_line)
          end

          def group_consecutive_assignments(assignments_by_line)
            groups        = []
            current_group = []
            previous_line = nil

            assignments_by_line.keys.sort.each do |line|
              if previous_line&.+(1) == line
                current_group << assignments_by_line[previous_line] if current_group.empty?
                current_group << assignments_by_line[line]
              else
                groups << current_group if current_group.size > 1
                current_group = [assignments_by_line[line]]
              end
              previous_line = line
            end

            groups << current_group if current_group.size > 1
            groups
          end

          def check_alignment(node)
            group = @assignment_groups.find {|g| g.include?(node) }
            return unless group

            target_column  = calculate_target_column(group)
            current_column = assignment_operator_column(node)

            return if current_column == target_column

            spaces_needed = target_column - current_column
            return if spaces_needed <= 0

            add_offense(node.source_range, :message => MSG) do |corrector|
              corrector.insert_before(assignment_operator_range(node), " " * spaces_needed)
            end
          end

          def calculate_target_column(group)
            base_column    = group.first.source_range.column
            max_var_length = group.map {|node| variable_name_length(node) }.max
            base_column + max_var_length + 1
          end

          def variable_name_length(node)
            case node.type
            when :lvasgn, :ivasgn, :cvasgn, :gvasgn
              node.children[0].to_s.length
            when :casgn
              if node.children[0]
                "#{node.children[0].source}::#{node.children[1]}".length
              else
                node.children[1].to_s.length
              end
            end
          end

          def assignment_operator_column(node)
            assignment_operator_range(node).column
          end

          def assignment_operator_range(node)
            source     = node.source
            equals_pos = source.index("=")
            return node.source_range if equals_pos.nil?

            start_pos = node.source_range.begin_pos + equals_pos
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
