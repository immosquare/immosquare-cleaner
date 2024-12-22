module RuboCop
  module Cop
    module CustomCops
      module Style
        class CommentNormalization < Base

          extend AutoCorrector

          MSG = "Comments should be normalized with the standard format".freeze
          BORDER_LINE = "###{"=" * 60}##".freeze

          def on_new_investigation
            comment_blocks = find_comment_blocks(processed_source.comments)

            comment_blocks.each do |block|
              next if block.empty?

              if needs_correction?(block)
                add_offense(block.first) do |corrector|
                  corrector.replace(
                    range_for_block(block),
                    normalize_comment_block(block)
                  )
                end
              end
            end
          end

          private

          def find_comment_blocks(comments)
            blocks = []
            current_block = []

            comments.each_with_index do |comment, index|
              if current_block.empty? || consecutive_comments?(comments[index - 1], comment)
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
            current_line = current_comment.location.line
            current_line == previous_line + 1
          end

          def needs_correction?(block)
            return true if block.first.text != BORDER_LINE
            return true if block.last.text != BORDER_LINE

            block.any? {|comment| !comment.text.start_with?("## ") }
          end

          def normalize_comment_block(block)
            normalized_lines = []
            normalized_lines << BORDER_LINE

            block.each do |comment|
              ##============================================================##
## Skip existing border lines
##============================================================##
              next if comment.text.start_with?("##=")

              ##============================================================##
## Remove existing comment markers and normalize
##============================================================##
              content = comment.text.gsub(/^#*\s*/, "").strip
              normalized_lines << "## #{content}" unless content.empty?
            end

            normalized_lines << BORDER_LINE
            normalized_lines.join("\n")
          end

          def range_for_block(block)
            start_pos = block.first.location.expression.begin_pos
            end_pos = block.last.location.expression.end_pos

            Parser::Source::Range.new(
              processed_source.buffer,
              start_pos,
              end_pos
            )
          end

        end
      end
    end
  end
end
