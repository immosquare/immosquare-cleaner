module RuboCop
  module Cop
    module Style
      class UseCredentialsInsteadOfEnv < Base


        extend AutoCorrector

        MSG = "Use Rails.application.credentials instead of ENV.fetch".freeze

        def on_send(node)
          return unless node.source == 'ENV.fetch("HELLO_WORLD", nil)'

          add_offense(node) do |corrector|
            corrector.replace(node, "Rails.application.credentials.hello_world")
          end
        end

      end
    end
  end
end
