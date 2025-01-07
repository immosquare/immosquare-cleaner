module RuboCop
  module Cop
    module CustomCops
      module Style
        class CommentNormalization < Base

          extend AutoCorrector

          MSG              = "Comments should be normalized with the standard format if start with ##".freeze
          BORDER_LINE      = "###{"=" * 60}##".freeze
          SPACE            = " ".freeze
          INSIDE_SEPARATOR = "###{SPACE}---------".freeze

          def on_new_investigation
            return if @investigation_in_progress

            @investigation_in_progress = true

            comment_blocks = find_comment_blocks(processed_source.comments)


            ##============================================================##
            ## On ne veut traiter que les blocs de commentaires où la première ligne
            ## du bloc commence par ##
            ##============================================================##
            comment_blocks = comment_blocks.select do |block|
              block.first.text.strip.start_with?("##")
            end


            comment_blocks.each do |block|
              correct_block = normalize_comment_block(block)


              if needs_correction?(block, correct_block)
                ##============================================================##
                ## Pour désactiver les cops autres cops qui pourraient être
                ## déclenchés par les commentaires
                ##============================================================##
                buffer    = processed_source.buffer
                start_pos = buffer.line_range(block.first.location.line).begin_pos
                end_pos   = buffer.line_range(block.last.location.line).end_pos
                range     = Parser::Source::Range.new(buffer, start_pos, end_pos)
                ignore_node(range)

                ##============================================================##
                ## Puis, on ajoute l'offense
                ##============================================================##
                add_offense(block.first) do |corrector|
                  corrector.replace(range, normalize_comment_block(block))
                end
              end
            end
          end



          private


          ##============================================================##
          ## On ne veut traiter que les commentaires qui ne sont pas
          ## des commentaires de fin de ligne ruby
          ##============================================================##
          def find_comment_blocks(comments)
            blocks              = []
            current_block       = []
            standalone_comments = comments.select do |comment|
              line = processed_source.lines[comment.location.line - 1]
              line.strip.start_with?("#")
            end

            standalone_comments.each_with_index do |comment, index|
              next_comment = standalone_comments[index + 1]

              if next_comment && next_comment.location.line == comment.location.line + 1
                current_block << comment
              else
                current_block << comment
                blocks << current_block.dup if !current_block.empty?
                current_block.clear
              end
            end
            blocks
          end

          ##============================================================##
          ## Pour formater correctement le block de commentaires
          ##============================================================##
          def normalize_comment_block(block)
            indent_level               = indent_level(block.first)
            first_line_with_text_found = false

            body = block.map do |comment|
              text                       = comment.text.to_s.strip
              chars                      = text.chars.uniq
              alphanumercic              = text.match?(/[\p{L}0-9]/)
              first_line_with_text_found = true if alphanumercic && !first_line_with_text_found
              if text == BORDER_LINE
                nil
              elsif alphanumercic
                cleaned_line(text)
              elsif !first_line_with_text_found
                nil
              else
                text == "##" ? "##" : INSIDE_SEPARATOR
              end
            end.compact


            body = ["## ..."] if body.empty?

            ##============================================================##
            ## Le block va être remis à la place du block original sur
            ## la colone du block original. Donc la première ligne du block
            ## ne doit pas être indentée manuellement. Par contre les autres
            ## lignes doivent être indentées sur la même colonne que la première
            ##============================================================##
            [BORDER_LINE, body, BORDER_LINE].flatten.map.with_index {|line, index| index == 0 ? line : "#{SPACE * indent_level}#{line}" }.join("\n")
          end

          def indent_level(line)
            line_content(line)[/\A */].size
          end

          ##============================================================##
          ## Pour récupérer le contenu de la ligne courante
          ##============================================================##
          def line_content(comment)
            processed_source.lines[comment.location.line - 1]
          end

          ##============================================================##
          ## Expliquons la regex :
          ## ## : match littéralement "##"
          ## | \s* : match 0 ou plusieurs espaces
          ## | #* : match 0 ou plusieurs #
          ## | \s* : match encore 0 ou plusieurs espaces
          ## | (?=[[:alnum:]]) : lookahead positif qui vérifie qu'on a un caractère alphanumérique après
          ##============================================================##
          def cleaned_line(line)
            if line.start_with?("## |")
              line
            elsif line.start_with?("##")
              line.gsub(/##\s*#*\s*(?=[[:alnum:]])/, "## ")
            else
              ##============================================================##
              ## Pour une ligne commençant par # simple, on la convertit en ##
              ## On enlève d'abord le # initial et tous les espaces qui suivent
              ##============================================================##
              cleaned = line.gsub(/^#\s*/, "")
              "## #{cleaned}"
            end
          end

          def needs_correction?(block, correct_block)
            block.map(&:text).map(&:strip).join("|") != correct_block.split("\n").map(&:strip).join("|")
          end

        end
      end
    end
  end
end
