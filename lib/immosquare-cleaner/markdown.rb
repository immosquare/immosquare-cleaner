module ImmosquareCleaner
  module Markdown
    class << self


      ##============================================================##
      ## we want to clean the markdown files to have a uniform style
      ## for the tables.
      ##============================================================##
      def clean(file_path)
        results           = []
        array_to_parse    = []
        prev_line_special = false

        ##============================================================##
        ## We parse each line of the file
        ##============================================================##
        File.foreach(file_path) do |line|
          if line.lstrip.start_with?("|")
            array_to_parse << line
          else
            if !array_to_parse.empty?
              results << cleaned_array(array_to_parse)
              array_to_parse = []
            end
            new_line, prev_line_special = cleaned_line(line, prev_line_special)
            results << new_line
          end
        end

        ##============================================================##
        ## Handle the case where the file ends with a table
        ##============================================================##
        results << cleaned_array(array_to_parse) if !array_to_parse.empty?

        results.join
      end


      private

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

      ##============================================================##
      ## We simply add a newline at the end of the line if needed
      ##============================================================##
      def cleaned_line(line, prev_line_special)
        cleaned           = line.rstrip
        blank_line        = line.gsub("\n", "").empty?
        special           = cleaned.lstrip.start_with?("*", "-", "+")
        new_line          = "#{"\n" if prev_line_special && !blank_line}#{cleaned}\n"
        prev_line_special = special
        [new_line, prev_line_special]
      end

    end
  end
end
