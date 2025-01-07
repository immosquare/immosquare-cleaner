module ImmosquareCleaner
  module Markdown
    class << self

      def clean(file_path)
        results        = []
        array_to_parse = []
        lines          = []

        ##============================================================##
        ## We parse each line of the file
        ##============================================================##
        File.foreach(file_path) do |current_line|
          ##============================================================##
          ## We save the last line to know if we need to add a newline
          ##============================================================##
          previous_line = lines.last
          lines << current_line

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
          cells = line.split("|").map(&:strip).reject(&:empty?)

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
              if cell&.match(/^-*$/)
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
        return [current_line] if !previous_line

        cleaned_current  = current_line.rstrip
        cleaned_previous = previous_line.rstrip
        blank_line       = current_line.gsub("\n", "").empty?
        previous_is_list = cleaned_previous.lstrip.start_with?("*", "-", "+")
        current_is_list  = cleaned_current.lstrip.start_with?("*", "-", "+")
        final            = previous_is_list && !current_is_list && !blank_line ? ["\n"] : []
        final << ["#{cleaned_current}\n"]
      end

    end
  end
end
