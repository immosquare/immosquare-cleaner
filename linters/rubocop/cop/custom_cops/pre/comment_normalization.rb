module RuboCop
  module Cop
    module CustomCops
      ##============================================================##
      ## Ce cop dépend du module PRE pour être lancer top dans le
      ## processus de vérification pour que ensuite Layout/CommentIndentation
      ## intende correctement les commentaires modifiés.
      ## Department Layout (y compris Layout/CommentIndentation)
      ## Department Lint
      ## Department Style
      ## Department Metricstoto
      ##============================================================##
      module Pre
        class CommentNormalization < Base

          extend AutoCorrector

          MSG         = "Comments should be normalized with the standard format if start with ##".freeze
          BORDER_LINE = "###{"=" * 60}##".freeze

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
            filtered_comments = comments.select {|comment| current_line(comment).strip.start_with?("##") }

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

          ##============================================================##
          ## Pour récupérer le contenu de la ligne courante
          ##============================================================##
          def current_line(comment)
            processed_source.lines[comment.location.line - 1]
          end

          def consecutive_comments?(previous_comment, current_comment)
            return false unless previous_comment && current_comment

            previous_line = previous_comment.location.line
            current_line  = current_comment.location.line
            current_line == previous_line + 1
          end

          def needs_correction?(block)
            indent          = indentation(block.first)
            expected_border = "#{indent}#{BORDER_LINE}"

            return false if block.first.text == expected_border &&
                            block.last.text == expected_border &&
                            block.all? {|comment| comment.text.start_with?("#{indent}## ") || comment.text == expected_border }

            true
          end

          def normalize_comment_block(block)
            indent           = indentation(block.first)
            normalized_lines = []

            normalized_lines << "#{indent}#{BORDER_LINE}"

            block.each do |comment|
              text = comment.text.to_s.strip
              next if text.start_with?("##=")

              text = "## #{text}" if !text.start_with?("## ")
              text = text.chomp("##").strip
              normalized_lines << "#{indent}#{text}"
            end

            normalized_lines << "#{indent}#{BORDER_LINE}"
            normalized_lines.join("\n")
          end

          def indentation(comment)
            comment.text.match(/^\s*/)[0]
          end

          def range_for_block(block)
            start_pos = block.first.location.expression.begin_pos
            end_pos = block.last.location.expression.end_pos

            Parser::Source::Range.new(processed_source.buffer, start_pos, end_pos)
          end

        end
      end
    end
  end
end
