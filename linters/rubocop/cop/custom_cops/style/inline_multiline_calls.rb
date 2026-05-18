module RuboCop
  module Cop
    module CustomCops
      module Style
        ##============================================================##
        ## Collapses multi-line method calls onto a single line when
        ## the method name is part of the configurable allowlist
        ## (`Methods`). No max-length cap — the call is always
        ## collapsed.
        ##
        ## Designed for helper-like calls that read cleaner inline
        ## (e.g. `link_to`, `button_to`, ...) but get split by hand
        ## or by other autocorrects.
        ##
        ## The cop walks the AST and rebuilds the call from each
        ## argument's source. This is intentionally safer than a
        ## regex-based collapse: comments inside the call and
        ## multi-line string literals would otherwise be silently
        ## corrupted, so the cop refuses to act on them.
        ##
        ## @example
        ## bad
        ## link_to(t("app.add.something"),
        ##         my_path(:id => id),
        ##         :class  => "dropdown-item",
        ##         :remote => true)
        ##
        ## good
        ## link_to(t("app.add.something"), my_path(:id => id), :class => "dropdown-item", :remote => true)
        ##============================================================##
        class InlineMultilineCalls < RuboCop::Cop::Base

          extend AutoCorrector

          MSG = "Collapse multi-line `%<name>s` call into a single line.".freeze

          DEFAULT_METHODS = ["link_to"].freeze

          def on_send(node)
            return unless target_methods.include?(node.method_name.to_s)
            return unless multiline_call?(node)
            return if contains_comment?(node)

            rebuilt = rebuild(node)
            return if rebuilt.nil?
            return if rebuilt.include?("\n")
            return if rebuilt == node.source

            add_offense(node, :message => format(MSG, :name => node.method_name)) do |corrector|
              corrector.replace(node, rebuilt)
            end
          end
          alias on_csend on_send

          private

          ##============================================================##
          ## A send node is multi-line if its source spans more than one
          ## line. We rely on the source range rather than `node.multiline?`
          ## because we want to react to formatting, not just node shape.
          ##============================================================##
          def multiline_call?(node)
            range = node.source_range
            range.first_line != range.last_line
          end

          ##============================================================##
          ## Refuse to act if any comment lives inside the call. Comments
          ## terminate at the next newline; collapsing newlines would
          ## swallow the args that follow the comment.
          ##============================================================##
          def contains_comment?(node)
            range = node.source_range
            processed_source.comments.any? do |comment|
              loc = comment.loc.expression
              loc.begin_pos >= range.begin_pos && loc.end_pos <= range.end_pos
            end
          end

          ##============================================================##
          ## Rebuild the call by joining each argument's source. Hash
          ## args are unfolded into their individual pairs so the joiner
          ## (", ") is consistent across all chunks. Returns nil when
          ## an individual arg is itself multi-line — a heredoc, a
          ## multi-line string literal, or a multi-line block expression
          ## inside an arg. Touching those would be unsafe.
          ##============================================================##
          def rebuild(node)
            chunks = node.arguments.flat_map do |arg|
              if arg.hash_type? && !arg.braces?
                arg.children.map(&:source)
              else
                [arg.source]
              end
            end

            return nil if chunks.any? {|src| src.include?("\n") }

            receiver_part = node.receiver ? "#{node.receiver.source}#{node.csend_type? ? "&." : "."}" : ""
            method_part   = node.method_name
            args_joined   = chunks.join(", ")

            if node.parenthesized?
              "#{receiver_part}#{method_part}(#{args_joined})"
            else
              "#{receiver_part}#{method_part} #{args_joined}"
            end
          end

          def target_methods
            Array(cop_config["Methods"]).map(&:to_s).then {|list| list.empty? ? DEFAULT_METHODS : list }
          end

        end
      end
    end
  end
end
