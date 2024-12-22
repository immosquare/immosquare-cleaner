module RuboCop
  module Cop
    module CustomCops
      ##============================================================##
      ## Ce cop dépend du module PRE pour être lancé en amont de
      ## Layout/CommentIndentation
      ## Dans l'odre les cops se lancent par Department puis par
      ## ordre alphabétique
      ## ---------
      ## Department Layout
      ## Department Lint
      ## Department Style
      ## Department Metricstoto
      ##============================================================##
      module Pre
        class CommentNormalization < Base

          extend AutoCorrector

          MSG         = "Comments should be normalized with the standard format if start with ##".freeze
          BORDER_LINE = "###{"=" * 60}##".freeze
          SPACE       = " ".freeze

          ##============================================================##
          ## 1 - var js, fjs = d.getElementsByTagName(s)[0];
          ## équivaut à var js = null et var fjs(first JS) d.getElementsByTagName(s)[0]
          ## On compile le fichier avec Terser pour qu'il soit minifié
          ##============================================================##
          def on_new_investigation
            comment_blocks = find_comment_blocks(processed_source.comments)

            comment_blocks.each do |block|
              add_offense(block.first) do |corrector|
                corrector.replace(range_for_block(block), normalize_comment_block(block))
              end if needs_correction?(block)
            end
          end

          private


          ##============================================================##
          ## On ne veut traiter  que les commentaires qui :
          ## - commencent par ## (et non #)
          ## - ne sont pas des commentaires de fin de ligne ruby
          ##============================================================##
          def find_comment_blocks(comments)
            blocks            = []
            current_block     = []
            filtered_comments = comments.select {|comment| line_content(comment).strip.start_with?("##") }

            filtered_comments.each do |comment|
              if current_block.empty? || consecutive_comments?(current_block.last, comment)
                current_block << comment
              else
                blocks << current_block unless current_block.empty?
                current_block = [comment]
              end
            end

            blocks << current_block unless current_block.empty?
            blocks
          end

          def consecutive_comments?(previous_comment, current_comment)
            return false unless previous_comment && current_comment

            previous_line = previous_comment.location.line
            current_line  = current_comment.location.line
            current_line == previous_line + 1
          end

          def needs_correction?(block)
            return false if block.first.text == BORDER_LINE && block.last.text == BORDER_LINE && block.all? {|comment| comment.text.start_with?("##") }

            true
          end

          ##============================================================##
          ## Pour formater correctement le block de commentaires
          ##============================================================##
          def normalize_comment_block(block)
            indent_level = indent_level(block.first)
            body         = block.map.with_index do |comment, index|
              text = comment.text.to_s.strip
              if text.start_with?("##=")
                index == 0 || index == block.size - 1 ? nil : "###{SPACE}---------"
              else
                text = "###{SPACE}#{text}" if !text.start_with?("###{SPACE}")
                text = text.chomp("##").strip
                text
              end
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

          def range_for_block(block)
            start_pos = block.first.location.expression.begin_pos
            end_pos   = block.last.location.expression.end_pos

            Parser::Source::Range.new(processed_source.buffer, start_pos, end_pos)
          end

        end
      end
    end
  end
end
