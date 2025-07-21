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
            @current_group = []
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

          def on_investigation_end
            # Finaliser le dernier groupe s'il y en a un
            finalize_current_group
            process_groups
          end

          private

          def check_assignment(node)
            # Vérifier que c'est bien un assignment simple (=) et pas (>=, <=, =>, etc.)
            return unless assignment_operator?(node)

            add_to_group(node)
          end

          def assignment_operator?(node)
            # Pour les assignments simples, on vérifie que le source contient un "="
            # mais pas ">=", "<=", "=>", etc.
            source = node.source.strip

            # Vérifier qu'il y a un "=" et qu'il n'est pas précédé ou suivi de caractères spéciaux
            return false unless source.include?("=")

            # Trouver la position du "="
            equals_pos = source.index("=")

            # Vérifier que le caractère avant "=" n'est pas ">" ou "<"
            return false if equals_pos > 0 && [">", "<"].include?(source[equals_pos - 1])

            # Vérifier que le caractère après "=" n'est pas ">"
            return false if equals_pos < source.length - 1 && source[equals_pos + 1] == ">"

            true
          end

          def add_to_group(node)
            current_line = node.location.line

            if @current_group.empty?
              @current_group = [node]
            elsif consecutive_lines?(@last_assignment_line, current_line)
              @current_group << node
            else
              # Nouveau groupe détecté, finaliser l'ancien
              finalize_current_group
              @current_group = [node]
            end
            @last_assignment_line = current_line
          end

          def consecutive_lines?(line1, line2)
            # Vérifier que les deux lignes sont consécutives
            # Si il y a une ligne vide ou plus entre elles, c'est un nouveau bloc
            gap = line2 - line1 - 1

            # Lignes consécutives seulement si pas de ligne vide entre elles
            gap == 0
          end

          def finalize_current_group
            if @current_group.length > 1
              @assignment_groups << @current_group.dup
              log_assignment_block(@current_group)
            end
            @current_group = []
            @last_assignment_line = nil
          end

          def log_assignment_block(group)
            start_line = group.first.location.line
            end_line = group.last.location.line

            puts("🔍 Bloc d'assignments détecté de la ligne #{start_line} à #{end_line}:")
            group.each do |node|
              puts("   Ligne #{node.location.line}: #{node.source}")
            end
            puts("")
          end

          def process_groups
            puts("🔧 Traitement de #{@assignment_groups.length} groupes d'assignments...")
            @assignment_groups.each do |group|
              # TODO: Implémenter la logique d'alignement
              puts("   Groupe avec #{group.length} assignments")
            end
          end

        end
      end
    end
  end
end
