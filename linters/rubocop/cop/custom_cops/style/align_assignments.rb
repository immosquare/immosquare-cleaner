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
          ## Pour les op-assignments (+=, -=, etc.)
          ##============================================================##
          def on_or_asgn(node)
            check_assignment(node)
          end

          def on_and_asgn(node)
            check_assignment(node)
          end

          ##============================================================##
          ## Pour les op-assignments (+=, -=, etc.)
          ##============================================================##
          def on_op_asgn(node)
            check_assignment(node)
          end

          ##============================================================##
          ## Pour les assignments d'index (listing["key"] = ...) et opérateurs (+=, -=)
          ##============================================================##
          def on_send(node)
            # Pour les index assignments
            if node.method_name == :[]= && node.arguments.length == 2
              check_assignment(node)
            end
          end

          def on_investigation_end
            finalize_current_group
            process_groups
          end

          private

          ##============================================================##
          ## Vérifier que c'est bien un assignment simple (=) et pas (>=, <=, =>, etc.)
          ##============================================================##
          def check_assignment(node)
            return unless assignment_operator?(node)

            add_to_group(node)
          end

          ##============================================================##
          ## Vérifier si l'opérateur est un simple "=" (pas >=, <=, =>, etc.)
          ##============================================================##
          def assignment_operator?(node)
            ##============================================================##
            ## Pour les send nodes (index assignment)
            ##============================================================##
            return true if node.respond_to?(:method_name) && node.method_name == :[]=

            ##============================================================##
            ## Pour les op-assignments (+=, -=, etc.)
            ##============================================================##
            return true if node.type == :op_asgn

            ##============================================================##
            ## Pour les assignments classiques
            ##============================================================##
            source = node.source.strip
            return false unless source.include?("=")

            equals_pos = source.index("=")
            return false if equals_pos > 0 && [">", "<"].include?(source[equals_pos - 1])
            return false if equals_pos < source.length - 1 && source[equals_pos + 1] == ">"

            true
          end

          ##============================================================##
          ## Ajouter un assignment au groupe courant ou créer un nouveau groupe
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
          ## Retourne true si les deux lignes sont consécutives (pas de ligne vide entre elles)
          ##============================================================##
          def consecutive_lines?(line1, line2)
            gap = line2 - line1 - 1
            gap == 0
          end

          ##============================================================##
          ## Finaliser le groupe courant s'il contient plus d'un assignment
          ##============================================================##
          def finalize_current_group
            @assignment_groups << @current_group.dup if @current_group.length > 1
            @current_group        = []
            @last_assignment_line = nil
          end

          ##============================================================##
          ## Traiter tous les groupes d'assignments pour vérifier l'alignement
          ##============================================================##
          def process_groups
            @assignment_groups.each do |group|
              check_and_correct_alignment(group)
            end
          end

          ##============================================================##
          ## Vérifier l'alignement d'un groupe et corriger si nécessaire
          ##============================================================##
          def check_and_correct_alignment(group)
            lefts = group.map do |node|
              source = node.source
              # Trouver l'opérateur d'assignment (=, +=, -=)
              operator = get_assignment_operator(source)
              parts = source.split(operator)
              parts[0].to_s.strip.gsub(/\s+/, "").gsub(",", ", ")
            end
            required_size = lefts.map(&:length).max + 1

            group.each.with_index do |node, index|
              current_source = node.source
              new_left = lefts[index]
              new_left += " " * (required_size - new_left.length)

              # Reconstruire la ligne avec le bon opérateur
              operator = get_assignment_operator(current_source)
              expected_source = reconstruct_assignment_line(current_source, new_left, operator)

              if current_source != expected_source
                add_offense(node, message: MSG) do |corrector|
                  corrector.replace(node, expected_source)
                end
              end
            end
          end

          ##============================================================##
          ## Déterminer l'opérateur d'assignment dans une ligne
          ##============================================================##
          def get_assignment_operator(source)
            if source.include?("+=")
              "+="
            elsif source.include?("-=")
              "-="
            else
              "="
            end
          end

          ##============================================================##
          ## Reconstruire une ligne d'assignment avec le bon alignement
          ##============================================================##
          def reconstruct_assignment_line(source, new_left, operator)
            split = source.split(operator)
            split[0] = new_left
            split.join(operator)
          end

        end
      end
    end
  end
end
