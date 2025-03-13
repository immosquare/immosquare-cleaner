module RuboCop
  module Cop
    module CustomCops
      module Style
        # This cop identifies usage of short Font Awesome prefix styles (e.g., 'fas', 'far', 'fal')
        # and suggests replacing them with the long version style (which is the standard since v6).
        #
        # Doc : https://docs.fontawesome.com/web/setup/upgrade/whats-changed#full-style-names
        #
        # @example
        #   # bad
        #   font_awesome_icon("fas fa-user")
        #   font_awesome_icon("far fa-circle-info")
        #   font_awesome_icon("fal fa-bell")
        #
        #   # good
        #   font_awesome_icon("fa-solid fa-user")
        #   font_awesome_icon("fa-regular fa-circle-info")
        #   font_awesome_icon("fa-light fa-bell")
        class FontAwesomeNormalization < RuboCop::Cop::Base

          extend AutoCorrector

          MSG = "Use long version Font Awesome style prefix instead of short version.".freeze

          # Mapping from short prefixes to long prefixes
          FA_PREFIX_MAP = {
            "fas"   => "fa-solid",
            "far"   => "fa-regular",
            "fal"   => "fa-light",
            "fat"   => "fa-thin",
            "fad"   => "fa-duotone fa-solid",
            "fadr"  => "fa-duotone fa-regular",
            "fadl"  => "fa-duotone fa-light",
            "fadt"  => "fa-duotone fa-thin",
            "fass"  => "fa-sharp fa-solid",
            "fasr"  => "fa-sharp fa-regular",
            "fasl"  => "fa-sharp fa-light",
            "fast"  => "fa-sharp fa-thin",
            "fasds" => "fa-sharp-duotone fa-solid",
            "fasdr" => "fa-sharp-duotone fa-regular",
            "fasdl" => "fa-sharp-duotone fa-light",
            "fasdt" => "fa-sharp-duotone fa-thin",
            "fab"   => "fa-brands"
          }.freeze

          def_node_matcher :font_awesome_icon_call?, <<~PATTERN
            (send nil? :font_awesome_icon $...)
          PATTERN

          def_node_matcher :string_argument?, <<~PATTERN
            (str $_)
          PATTERN

          def on_send(node)
            font_awesome_icon_call?(node) do |args|
              first_arg = args&.first
              return unless first_arg

              if first_arg.str_type?
                # Handle simple string literals
                string_content = first_arg.str_content
                return if string_content.to_s.empty?

                process_fa_content(first_arg, string_content) do |new_content|
                  "\"#{new_content}\""
                end
              elsif first_arg.dstr_type?
                # Handle interpolated strings like "fal fa-#{icon}"
                first_arg.children.each do |child|
                  next unless child.str_type?

                  string_content = child.str_content
                  next if string_content.to_s.empty?

                  process_fa_content(child, string_content) do |new_content|
                    new_content # No need to add quotes for parts of interpolated string
                  end
                end
              end
            end
          end

          def process_fa_content(node, content)
            FA_PREFIX_MAP.each do |short_prefix, long_prefix|
              pattern = /\b#{Regexp.escape(short_prefix)}\s+fa-/

              if content.match?(pattern)
                new_content = content.gsub(pattern, "#{long_prefix} fa-")

                add_offense(node, :message => MSG) do |corrector|
                  replacement = yield(new_content)
                  corrector.replace(node, replacement)
                end

                # Once we've found a match, no need to check other prefixes
                break
              end
            end
          end

        end
      end
    end
  end
end
