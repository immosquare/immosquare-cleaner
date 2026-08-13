module ImmosquareCleaner
  module Markdown
    class << self

      ##============================================================##
      ## A fenced code block opens/closes with a line whose first
      ## non-space chars are ``` or ~~~ (optionally followed by a
      ## language tag). Inside such a block we must NOT reformat —
      ## a Ruby snippet with `|` would otherwise be parsed as a
      ## markdown table.
      ##
      ## Per CommonMark, the closing fence must use the same marker
      ## (``` or ~~~) as the opening, so we track which marker
      ## opened the block — otherwise a ~~~ line shown inside a
      ## ``` block (e.g. when documenting markdown itself) would
      ## prematurely close the fence.
      ##============================================================##
      FENCE_REGEX = /\A\s*(```|~~~)/

      ##============================================================##
      ## A list item marker is `*`, `+` or `-` followed by a space,
      ## or alone on its line. The space is what makes it a list:
      ## without that requirement `---` — a thematic break, and the
      ## fence of a YAML frontmatter — and `*emphasis*` opening a
      ## line are both read as list items, which injects a blank
      ## line right after them. Inside a frontmatter that blank line
      ## lands between the opening fence and the first key.
      ##============================================================##
      LIST_ITEM_REGEX = /\A[*+-](\s|\z)/

      ##============================================================##
      ## The fence of a YAML frontmatter: `---` alone on its line.
      ##============================================================##
      FRONTMATTER_FENCE_REGEX = /\A---\s*\z/

      def clean(file_path)
        results            = []
        array_to_parse     = []
        lines              = []
        fence_marker       = nil
        frontmatter_last   = frontmatter_last_index(file_path)
        frontmatter_opened = false

        ##============================================================##
        ## We parse each line of the file
        ##============================================================##
        File.foreach(file_path).with_index do |current_line, index|
          ##============================================================##
          ## A frontmatter is YAML, not markdown: it goes through
          ## verbatim. Neither the list spacing nor the table rules
          ## mean anything between its fences, and applying them adds
          ## a blank line after the opening fence — or before the
          ## closing one when the last key holds a list.
          ##
          ## Its leading blank lines are the one exception, and they
          ## are dropped: never meaningful in YAML, and earlier
          ## versions of this cleaner injected one there by taking the
          ## opening `---` for a list item. Removing it here repairs
          ## the files that already carry it.
          ##============================================================##
          if frontmatter_last && index <= frontmatter_last
            lines << current_line

            if index > 0 && index < frontmatter_last && !frontmatter_opened
              next if current_line.strip.empty?

              frontmatter_opened = true
            end

            results << current_line
            next
          end

          ##============================================================##
          ## We save the last line to know if we need to add a newline
          ##============================================================##
          previous_line = lines.last
          lines << current_line

          ##============================================================##
          ## Detect entering/exiting a fenced code block. Inside a
          ## fence, only a line whose marker matches the opening one
          ## closes it; any other fence marker is emitted verbatim.
          ##============================================================##
          fence_match = current_line.match(FENCE_REGEX)

          if fence_match && (fence_marker.nil? || fence_marker == fence_match[1])
            if !array_to_parse.empty?
              results << cleaned_array(array_to_parse)
              array_to_parse = []
            end
            results << current_line
            fence_marker = fence_marker.nil? ? fence_match[1] : nil
            next
          end

          if fence_marker
            results << current_line
            next
          end

          ##============================================================##
          ## We add the line to the array if it starts with a pipe
          ##============================================================##
          if current_line.lstrip.start_with?("|")
            array_to_parse << current_line
          else
            if !array_to_parse.empty?
              results << cleaned_array(array_to_parse)
              array_to_parse = []
            end
            new_lines = cleaned_line(previous_line, current_line)
            results += new_lines
          end
        end

        ##============================================================##
        ## Handle the case where the file ends with a table
        ##============================================================##
        results << cleaned_array(array_to_parse) if !array_to_parse.empty?

        results.join
      end


      private

      ##============================================================##
      ## Index of the closing fence of the frontmatter, or nil when
      ## the file has none. A frontmatter only exists when `---` is
      ## the very first line AND a closing `---` follows: without
      ## that second condition, a file opening on a thematic break
      ## would be emitted verbatim from end to end.
      ##============================================================##
      def frontmatter_last_index(file_path)
        first_line = File.foreach(file_path).first
        return nil if first_line.nil? || !first_line.match?(FRONTMATTER_FENCE_REGEX)

        File.foreach(file_path).with_index do |line, index|
          next if index == 0
          return index if line.match?(FRONTMATTER_FENCE_REGEX)
        end

        nil
      end

      ##============================================================##
      ## we want to clean the markdown files to have a uniform style
      ## for the tables.
      ##============================================================##
      def cleaned_array(array_to_clean)
        ##============================================================##
        ## We split each line of the array and remove the empty cells
        ## we also save the max lenght of each position in x.
        ##============================================================##
        elements_size = []
        rows = array_to_clean.map do |line|
          ##============================================================##
          ## Only the delimiting pipes are dropped, never empty cells:
          ## a table may legitimately hold one (an unnamed first header
          ## above a column of row labels, a value that does not apply).
          ## Rejecting empty cells would shift every following cell one
          ## column to the left and silently file values under the wrong
          ## header. `split("|", -1)` keeps trailing empty fields.
          ##============================================================##
          cells = line.strip.delete_prefix("|").delete_suffix("|").split("|", -1).map(&:strip)

          ##============================================================##
          ## We increase the size of the array if needed
          ##============================================================##
          elements_size += Array.new(cells.length - elements_size.size, 0) if cells.length > elements_size.length

          ##============================================================##
          ## We update the max length of each position in x
          ##============================================================##
          cells.map(&:length).zip(elements_size).each_with_index do |(cell_length, max_length), index|
            elements_size[index] = [cell_length, max_length].max
          end

          cells
        end

        ##============================================================##
        ## We fill the empty cells with nil to have uniform rows
        ##============================================================##
        rows.each {|row| row.fill(nil, row.length...elements_size.size) }


        formatted_rows = rows.map do |row|
          line = row.each_with_index.map do |cell, index|
            max_length = elements_size[index]
            cell =
              ##============================================================##
              ## At least one dash is required: an empty cell must stay
              ## empty, not be filled with dashes that would read as a
              ## separator row.
              ##============================================================##
              if cell&.match(/\A-+\z/)
                "-" * max_length
              else
                cell.to_s.ljust(max_length)
              end
          end.join(" | ")
          "| #{line} |"
        end

        "#{formatted_rows.join("\n")}\n"
      end

      def cleaned_line(previous_line, current_line)
        cleaned_current = current_line.rstrip

        ##============================================================##
        ## The very first line of the file has no predecessor, so no
        ## list spacing to decide — but it still gets its trailing
        ## whitespace stripped like any other line.
        ##============================================================##
        return ["#{cleaned_current}\n"] if !previous_line

        cleaned_previous = previous_line.rstrip
        blank_line       = current_line.gsub("\n", "").empty?
        previous_is_list = cleaned_previous.lstrip.match?(LIST_ITEM_REGEX)
        current_is_list  = cleaned_current.lstrip.match?(LIST_ITEM_REGEX)
        final            = previous_is_list && !current_is_list && !blank_line ? ["\n"] : []
        final << ["#{cleaned_current}\n"]
      end

    end
  end
end
