module RuboCop
  module Cop
    module CustomCops
      module Style
        ##============================================================##
        ## Custom Cop: UseCredentialsInsteadOfEnv
        ## To replace ENV.fetch with Rails.application.credentials
        ##============================================================##
        class UseCredentialsInsteadOfEnv < Base

          extend AutoCorrector

          MSG = "Use Rails.application.credentials instead of ENV.fetch".freeze

          ##============================================================##
          ## Node Matcher
          ##============================================================##
          def_node_matcher :env_fetch?, <<~PATTERN
            (send (const nil? :ENV) :fetch ...)
          PATTERN

          def on_send(node)
            return if !env_fetch?(node)

            ##============================================================##
            ## ENV.fetch("hello_world", nil)            => Rails.application.credentials.hello_world
            ## ENV.fetch("hello_world_#{user_id}", nil) => Rails.application.credentials["hello_world_#{user_id}"]
            ##============================================================##
            add_offense(node) do |corrector|
              key   = node.arguments.first
              value = key.type == :dstr ? "[#{key.source}]" : ".#{key.source.delete('"')}"
              corrector.replace(node, "Rails.application.credentials#{value}")
            end
          end

        end
      end
    end
  end
end
