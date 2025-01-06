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
            comment_blocks = find_comment_blocks(processed_source.comments)


            comment_blocks.each do |block|
              if needs_correction?(block)
                ##============================================================##
                ## Pour désactiver les cops suivants
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
          ## On ne veut traiter que les commentaires qui :
          ## - commencent par ## (et non #)
          ## - ne sont pas des commentaires de fin de ligne ruby
          ##============================================================##
          def find_comment_blocks(comments)
            blocks            = []
            current_block     = []
            filtered_comments = comments.select {|comment| line_content(comment).strip.start_with?("##") }

            filtered_comments.each do |comment|
              if current_block.empty? || comment.location.line == current_block.last.location.line + 1
                current_block << comment
              else
                blocks << current_block
                current_block = [comment]
              end
            end

            blocks << current_block
            blocks
          end

          ##============================================================##
          ## Nous n'avons pas besoin de corriger les commentaires si :
          ## - le premier et le dernier commentaire sont des lignes de bordure
          ## - tous les commentaires commencent par ##
          ## - il n'y a pas de ligne autre que les lignes de bordure qui commence par ##=
          ##============================================================##
          def needs_correction?(block)
            return false if block.compact.empty?

            ##============================================================##
            ## un block de commentaires ne peut pas être composé de moins de 3 lignes (border, body, border)
            ##============================================================##
            return true if block.size < 3

            ##============================================================##
            ## On retourne true si une ligne du block contient que les caractères de bordure sans que cela soit une ligne de bordure
            ##============================================================##
            return true if block[1..-2].any? {|comment| comment.text.chars.uniq.compact.sort == [" ", "#", "="] }

            return false if block.first.text == BORDER_LINE &&
                            block.last.text == BORDER_LINE &&
                            block.all? {|comment| comment.text.start_with?("##") } &&
                            block.each_with_index.none? do |comment, index|
                              index != 0 &&
                              index != block.length - 1 &&
                              comment.text.start_with?("##=")
                            end


            true
          end

          ##============================================================##
          ## Pour formater correctement le block de commentaires
          ##============================================================##
          def normalize_comment_block(block)
            indent_level = indent_level(block.first)
            body         = block.map.with_index do |comment, index|
              ##============================================================##
              ## On met un espace après les ## si le caractère n'est pas un espace
              ##============================================================##
              text = comment.text.to_s.strip
              text = text.gsub(/^##(?![=\s])/, "###{SPACE}")
              if text.start_with?("##=") || text.start_with?("#=")
                index == 0 || index == block.size - 1 ? nil : INSIDE_SEPARATOR
              else
                text = "###{SPACE}#{text}" if !text.start_with?("###{SPACE}")
                text = text.chomp("##").strip
                text
              end
            end.compact

            ##============================================================##
            ## On efface les lignes du body qui serait des lignes de bordure (bien formatée ou non)
            ##============================================================##
            body = body.map do |line|
              chars = line.chars.uniq.compact.sort
              [[" ", "#", "="], ["#", "="]].include?(chars) ? INSIDE_SEPARATOR : line
            end.compact


            ##============================================================##
            ## Le block va être remis à la place du block original sur
            ## la colone du block original. Donc la première ligne du block
            ## ne doit pas être indentée manuellement. Par contre les autres
            ## lignes doivent être indentées sur la même colonne que la première
            ##============================================================##
            [BORDER_LINE, body, BORDER_LINE].flatten.map.with_index {|line, index| index == 0 ? line : "#{SPACE * indent_level}#{line}" }.join("\n")
          end

          ##============================================================##
          ## Pour récupérer le contenu de la ligne courante
          ##============================================================##
          def line_content(comment)
            processed_source.lines[comment.location.line - 1]
          end

          def indent_level(line)
            line_content(line)[/\A */].size
          end


        end
      end
    end
  end
end
