# Acme's Elixir workloads can efficiently use up the entire node.
# This mixins adds helpers for scheduling workloads on nodepools
# set aside for that

module Acme
  module Nodes
    module RequiredCores
      extend Concern

      included do
        let(:required_cores) { fail Matsuri::UndefinedLet, "Must define let(:required_cores)" }

        let(:cores_node_selector) { { 'cores' => required_cores } }
        let(:cores_toleration) do
          tolerate \
            key:       'cores',
            operator: 'Equal',
            value:     required_cores,
            effect:    'NoSchedule'
        end
      end
    end
  end
end


