module RuboCop
  module Cop
    module CustomCops
      module Style
        ##============================================================##
        ## This cop aligns the blocks of Rails routes in
        ## `config/routes.rb` and `config/routes/*.rb`: inside a
        ## block of consecutive route lines, the verb, the path,
        ## the target and every option (`:as`, `:via`,
        ## `:constraints`...) start in the same column. Options are
        ## aligned by name: a route without `:via` leaves that
        ## column empty and its `:as` lands under the `:as` of its
        ## neighbours.
        ##
        ## Only whitespace changes: paths, targets, options and
        ## comments come out identical, in the same order. The
        ## corrections only rewrite the gaps between tokens, never
        ## a token itself, so they cannot clash with the
        ## corrections of other cops.
        ##
        ## The option columns follow an order compatible with the
        ## order of every route in the block (`:via` before `:as`
        ## when a route carries them in that order, even when a
        ## neighbour without `:via` meets `:as` first). When two
        ## routes impose opposite orders, the block is left alone:
        ## no alignment can satisfy both without reordering.
        ##
        ## Recognized shapes: `get "a" => "c#a", :as => ...`, the
        ## same call with parentheses (`match("a" => "c#a", ...)`),
        ## and the shape without a positional target
        ## (`match "404", :to => ...`).
        ##
        ## @example
        ## bad
        ## get "users" => "users#index", :as => :users
        ## match "users/:id" => "users#update", :via => [:patch, :put], :as => :user
        ##
        ## good
        ## get   "users"     => "users#index",                            :as => :users
        ## match "users/:id" => "users#update", :via => [:patch, :put], :as => :user
        ##============================================================##
        class AlignRoutes < RuboCop::Cop::Base

          extend AutoCorrector

          MSG = "Align the columns of consecutive routes.".freeze

          VERBS = [:get, :post, :put, :patch, :delete, :match].freeze

          ##============================================================##
          ## Only the files Rails loads its routes from. A `get`
          ## call anywhere else is not a route.
          ##============================================================##
          ROUTES_FILE = %r{config/routes(?:/[^/]+\.rb|\.rb)\z}

          def on_new_investigation
            @routes = []
          end

          def on_send(node)
            return unless routes_file?
            return unless VERBS.include?(node.method_name)
            return unless node.receiver.nil?

            route = parse_route(node)
            @routes << route if route
          end

          def on_investigation_end
            groups.each {|group| check_group(group) }
          end

          private

          def routes_file?
            path = processed_source.file_path
            path.nil? || ROUTES_FILE.match?(path.to_s)
          end

          ##============================================================##
          ## A route line cut into segments: verb, path, target when
          ## there is one, then its options under their name (`:as`,
          ## `:via`...), in the order the line carries them. Every
          ## segment keeps its source range, so the corrections can
          ## address the gaps between segments. Nil when the call
          ## is not a single-line route starting its line.
          ##============================================================##
          def parse_route(node)
            range = node.source_range
            return if range.first_line != range.last_line

            line = processed_source.lines[range.first_line - 1]
            return if line.nil? || !line.strip.start_with?(node.source.strip)

            first = node.arguments.first
            return if first.nil?

            if first.hash_type?
              return if first.braces? || first.pairs.empty?

              pair = first.pairs.first
              return unless pair.key.str_type?

              target_pair = pair
              path_range  = pair.key.source_range
              rest_pairs  = first.pairs.drop(1)
            elsif first.str_type?
              target_pair = nil
              path_range  = first.source_range
              rest_pairs  = []
              if node.arguments.size > 1
                hash = node.arguments[1]
                return unless hash.hash_type? && !hash.braces?

                rest_pairs = hash.pairs
              end
            else
              return
            end

            segments = [{:kind => :path, :range => path_range}]
            segments << {:kind => :target, :range => target_pair.value.source_range, :pair => target_pair} if target_pair
            rest_pairs.each_with_index do |pair, index|
              key = pair.key.sym_type? ? ":#{pair.key.value}" : "__raw#{index}"
              segments << {:kind => :option, :key => key, :range => pair.source_range}
            end

            {:node => node, :line => range.first_line, :segments => segments}
          end

          ##============================================================##
          ## Blocks of routes on adjacent lines. Any other line
          ## (comment, `scope`, `end`, a route this cop does not
          ## recognize...) puts at least one line between two
          ## routes and so closes the block. Two routes sharing a
          ## line are dropped: aligning them would rewrite the
          ## same line twice.
          ##============================================================##
          def groups
            sorted = @routes.sort_by {|route| route[:node].source_range.begin_pos }
            counts = sorted.map {|route| route[:line] }.tally
            sorted = sorted.reject {|route| counts[route[:line]] > 1 }

            sorted.chunk_while {|a, b| b[:line] == a[:line] + 1 }.to_a
          end

          ##============================================================##
          ## Check one block: compute the column of every segment,
          ## then flag each route whose gaps differ, correcting
          ## gap by gap.
          ##============================================================##
          def check_group(group)
            return if group.size < 2

            keys = ordered_keys(group)
            return if keys.nil?

            place_segments(group, keys)

            group.each do |route|
              corrections = corrections_for(route)
              next if corrections.empty?

              add_offense(route[:node], :message => MSG) do |corrector|
                corrections.each {|range, text| corrector.replace(range, text) }
              end
            end
          end

          ##============================================================##
          ## The column of every segment of every route of the
          ## block: first `=>` in one column, then one column per
          ## option name, in the order computed for the block. The
          ## comma stays glued to the value before it, the spaces
          ## follow it.
          ##============================================================##
          def place_segments(group, keys)
            verb_width = group.map {|route| route[:node].method_name.length }.max
            path_width = group.map {|route| segment(route, :path)[:range].size }.max

            group.each do |route|
              node       = route[:node]
              path_start = node.source_range.column + verb_width + 1
              segment(route, :path)[:start] = path_start

              target = segment(route, :target)
              head_end =
                if target
                  target[:start] = path_start + path_width + 4
                  target[:start] + target[:range].size
                else
                  path_start + path_width
                end
              route[:head_end] = head_end
            end

            starts = {}
            column = group.map {|route| route[:head_end] }.max + 2
            keys.each do |key|
              starts[key] = column
              followers = keys.drop(keys.index(key) + 1)
              ends      = group.filter_map do |route|
                option = route[:segments].find {|seg| seg[:key] == key }
                column + option[:range].size if option && (option_keys(route) & followers).any?
              end
              column = ends.max + 2 if ends.any?
            end

            group.each do |route|
              route[:segments].each do |seg|
                seg[:start] = starts[seg[:key]] if seg[:kind] == :option
              end
            end
          end

          ##============================================================##
          ## The gaps of one route that do not match the computed
          ## columns, as [range, expected text] pairs. Ranges only
          ## ever span whitespace and the commas separating the
          ## segments, never a segment itself.
          ##============================================================##
          def corrections_for(route)
            node        = route[:node]
            selector    = node.loc.selector
            path        = segment(route, :path)
            corrections = []

            if node.loc.begin
              replace_gap(corrections, selector.end_pos, node.loc.begin.begin_pos, "")
              replace_gap(corrections, node.loc.begin.end_pos, path[:range].begin_pos, "")
            else
              replace_gap(corrections, selector.end_pos, path[:range].begin_pos,
                " " * (path[:start] - selector.column - selector.size))
            end

            previous = path
            if (target = segment(route, :target))
              operator = target[:pair].loc.operator
              ##============================================================##
              ## The `=>` sits 3 columns before the target (its 2
              ## chars plus the space after it); the path ends, in
              ## the aligned line, at its start plus its length.
              ##============================================================##
              replace_gap(corrections, path[:range].end_pos, operator.begin_pos,
                " " * ((target[:start] - 3) - (path[:start] + path[:range].size)))
              replace_gap(corrections, operator.end_pos, target[:range].begin_pos, " ")
              previous = target
            end

            route[:segments].select {|seg| seg[:kind] == :option }.each do |option|
              prev_end = previous[:start] + previous[:range].size
              replace_gap(corrections, previous[:range].end_pos, option[:range].begin_pos,
                ",#{" " * (option[:start] - prev_end - 1)}")
              previous = option
            end
            corrections
          end

          ##============================================================##
          ## Record a gap correction when the current text differs.
          ##============================================================##
          def replace_gap(corrections, begin_pos, end_pos, expected)
            range = Parser::Source::Range.new(processed_source.buffer, begin_pos, end_pos)
            return if range.source == expected

            corrections << [range, expected]
          end

          def segment(route, kind)
            route[:segments].find {|seg| seg[:kind] == kind }
          end

          def option_keys(route)
            route[:segments].filter_map {|seg| seg[:key] }
          end

          ##============================================================##
          ## The order of the option columns: the first one
          ## compatible with the order every route gives its
          ## options, keeping first-encounter order on ties. Nil
          ## when two routes impose opposite orders.
          ##============================================================##
          def ordered_keys(group)
            keys         = group.flat_map {|route| option_keys(route) }.uniq
            predecessors = Hash.new {|hash, key| hash[key] = [] }
            group.each do |route|
              option_keys(route).each_cons(2) do |before, after|
                predecessors[after] << before unless predecessors[after].include?(before)
              end
            end

            sorted    = []
            remaining = keys.dup
            while remaining.any?
              ready = remaining.select {|key| (predecessors[key] - sorted).empty? }
              return if ready.empty?

              sorted << ready.first
              remaining.delete(ready.first)
            end
            sorted
          end

        end
      end
    end
  end
end
