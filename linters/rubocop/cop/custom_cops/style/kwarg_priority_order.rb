module RuboCop
  module Cop
    module CustomCops
      module Style
        ##============================================================##
        ## Reorders the kwargs (implicit hash arg) of configured method
        ## calls so that priority keys come first, in the order given
        ## by `PriorityKeys`. Other kwargs keep their relative order.
        ##
        ## Targets the last positional arg only when it is a non-braced
        ## hash (i.e. a real kwargs trailing hash). Explicit `{ ... }`
        ## hash literals are left untouched.
        ##
        ## @example PriorityKeys: ["remote", "method"]
        ## bad
        ## link_to(t("x"), path, :class => "x", :remote => true)
        ## link_to(t("x"), path, :class => "x", :method => :delete)
        ##
        ## good
        ## link_to(t("x"), path, :remote => true, :class => "x")
        ## link_to(t("x"), path, :method => :delete, :class => "x")
        ##============================================================##
        class KwargPriorityOrder < RuboCop::Cop::Base

          extend AutoCorrector

          MSG = "Move priority kwargs (%<keys>s) to the front of the call.".freeze

          DEFAULT_METHODS = ["link_to"].freeze
          DEFAULT_PRIORITY_KEYS = ["remote", "method"].freeze

          def on_send(node)
            return unless target_methods.include?(node.method_name.to_s)

            hash_arg = node.last_argument
            return unless hash_arg&.hash_type?
            return if hash_arg.braces?

            pairs = hash_arg.children
            return if pairs.size < 2

            priority_pairs, rest = partition_priority(pairs)
            return if priority_pairs.empty?
            return if pairs.first(priority_pairs.size) == priority_pairs

            new_hash_src = (priority_pairs + rest).map {|p| p.loc.expression.source }.join(", ")
            return if new_hash_src == hash_arg.loc.expression.source

            add_offense(hash_arg, :message => format(MSG, :keys => priority_keys.join(", "))) do |corrector|
              corrector.replace(hash_arg, new_hash_src)
            end
          end
          alias on_csend on_send

          private

          ##============================================================##
          ## Split pairs into priority (in PriorityKeys order) and rest
          ## (original order preserved).
          ##============================================================##
          def partition_priority(pairs)
            by_key = {}
            rest   = []

            pairs.each do |pair|
              key_str = key_name(pair.children.first)
              if key_str && priority_keys.include?(key_str)
                by_key[key_str] = pair
              else
                rest << pair
              end
            end

            priority = priority_keys.filter_map {|k| by_key[k] }
            [priority, rest]
          end

          ##============================================================##
          ## Extract the key name from a hash pair's key node. Handles
          ## :sym, "string", and dynamic keys (returns nil for the
          ## latter so they're treated as non-priority).
          ##============================================================##
          def key_name(key_node)
            return nil unless key_node

            case key_node.type
            when :sym, :str then key_node.value.to_s
            end
          end

          def priority_keys
            Array(cop_config["PriorityKeys"]).map(&:to_s).then {|list| list.empty? ? DEFAULT_PRIORITY_KEYS : list }
          end

          def target_methods
            Array(cop_config["Methods"]).map(&:to_s).then {|list| list.empty? ? DEFAULT_METHODS : list }
          end

        end
      end
    end
  end
end
