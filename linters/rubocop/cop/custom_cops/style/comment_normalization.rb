module RuboCop
  module Cop
    module CustomCops
      module Style
        class CommentNormalization < Base

          extend AutoCorrector

          MSG              = "Comments should be normalized with the standard format if start with ##".freeze
          BORDER_LINE      = "###{"=" * 60}##".freeze
          INSIDE_SEPARATOR = "## ---------".freeze
          BLANK_LINE       = "##".freeze
          EMPTY_BODY       = "## ...".freeze
          SPACE            = " ".freeze

          ##============================================================##
          ## Patterns detected line by line within a block:
          ## - STRUCTURED_LINE : bullets, quotes, numbered lists
          ## - INDENTED_LINE   : explicit indentation (3+ spaces after ##)
          ## - RAW_LINE        : line preserved as-is (## | ...)
          ## - FENCE_LINE      : open/close of a code block (## ```)
          ## - USER_SEPARATOR  : explicit separator (## ---, ===, ___)
          ##============================================================##
          STRUCTURED_LINE = /\A##\s+([-*+>]|\d+[.)])\s/
          INDENTED_LINE   = /\A##\s{3,}\S/
          RAW_LINE        = /\A##\s*\|/
          FENCE_LINE      = /\A##\s*```/
          USER_SEPARATOR  = /\A##\s*[-=_]{3,}\s*\z/

          def on_new_investigation
            return if @investigation_in_progress

            @investigation_in_progress = true

            find_comment_blocks(processed_source.comments).each do |block|
              normalized = normalize_comment_block(block)
              next if !needs_correction?(block, normalized)

              range = block_range(block)
              ignore_node(range)
              add_offense(block.first) do |corrector|
                corrector.replace(range, normalized)
              end
            end
          end

          private

          ##============================================================##
          ## Only process comments that start at the beginning of the
          ## line with "##" (not Ruby end-of-line comments).
          ## Blocks are runs of contiguous lines.
          ##============================================================##
          def find_comment_blocks(comments)
            standalone = comments.select do |comment|
              processed_source.lines[comment.location.line - 1].lstrip.start_with?("##")
            end

            standalone.slice_when {|prev, nxt| nxt.location.line != prev.location.line + 1 }.to_a
          end

          def block_range(block)
            buffer    = processed_source.buffer
            start_pos = buffer.line_range(block.first.location.line).begin_pos
            end_pos   = buffer.line_range(block.last.location.line).end_pos
            Parser::Source::Range.new(buffer, start_pos, end_pos)
          end

          ##============================================================##
          ## Wraps the body with BORDER_LINE and indents every line to
          ## the original block's column. The replaced range starts at
          ## column 0, so the first line must also receive the pad.
          ##============================================================##
          def normalize_comment_block(block)
            body = build_body(block)
            body = [EMPTY_BODY] if body.empty?

            pad = SPACE * indent_level(block.first)
            [BORDER_LINE, *body, BORDER_LINE].map {|line| "#{pad}#{line}" }.join("\n")
          end

          ##============================================================##
          ## Transforms each line of the block:
          ## - existing borders            → dropped
          ## - leading blank lines         → dropped (before any content)
          ## - fenced code blocks (## ```) → content preserved as-is
          ## - raw lines (## | ...)        → preserved
          ## - lists / 3+ indent           → preserved
          ## - separators (## ---)         → INSIDE_SEPARATOR
          ## - bare "##" lines             → kept as blank line
          ## - normal text                 → cleaned via #cleaned_line
          ##============================================================##
          def build_body(block)
            body         = []
            in_code      = false
            content_seen = false

            block.each do |comment|
              text = comment.text.to_s.rstrip

              if text == BORDER_LINE
                next
              elsif text.match?(FENCE_LINE)
                in_code = !in_code
                body << text
                content_seen = true
              elsif in_code || text.match?(RAW_LINE)
                body << text
                content_seen = true
              elsif text == BLANK_LINE
                body << BLANK_LINE if content_seen
              elsif text.match?(USER_SEPARATOR)
                body << INSIDE_SEPARATOR if content_seen
              elsif text.match?(STRUCTURED_LINE) || text.match?(INDENTED_LINE)
                body << text
                content_seen = true
              else
                body << cleaned_line(text)
                content_seen = true
              end
            end

            body
          end

          ##============================================================##
          ## Cleans up a standard text line:
          ## - "### foo"  → "## foo"  (collapse repeated #)
          ## - "##  foo"  → "## foo"  (single space after ##)
          ## NB: lines with 3+ intentional spaces are already caught
          ## upstream by INDENTED_LINE.
          ##============================================================##
          def cleaned_line(text)
            text.sub(/\A##\s*#+\s*(?=\S)/, "## ").sub(/\A##\s+(?=\S)/, "## ")
          end

          def indent_level(comment)
            processed_source.lines[comment.location.line - 1][/\A */].size
          end

          ##============================================================##
          ## Compare lines after stripping: we ignore indentation
          ## differences since the range already targets the right column.
          ##============================================================##
          def needs_correction?(block, normalized)
            current_lines    = block.map {|c| c.text.to_s.strip }
            normalized_lines = normalized.split("\n").map(&:strip)
            current_lines != normalized_lines
          end

        end
      end
    end
  end
end
