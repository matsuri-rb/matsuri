# Acme's Elixir workloads can efficiently use up the entire node.
# This mixins adds helpers for scheduling workloads on nodepools
# set aside for that

module Acme
  module Nodes
    module Dedicated
      extend Concern

      included do
        let(:dedicated_key) { fail Matsuri::UndefinedLet, "Must define let(:dedicated_key)" }

        let(:dedicated_node_selector) { { 'dedicated' => dedicated_key } }
        let(:dedicated_toleration) do
          tolerate \
            key:      'dedicated',
            operator: 'Equal',
            value:     dedicated_key,
            effect:    'NoSchedule'
        end
      end
    end
  end
end


