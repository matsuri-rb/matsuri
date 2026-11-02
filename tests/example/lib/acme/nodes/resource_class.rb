# Acme's Elixir workloads can efficiently use up the entire node.
# This mixins adds helpers for scheduling workloads on nodepools
# set aside for that

module Acme
  module Nodes
    module ResourceClass
      extend Concern

      included do
        let(:big_disk_toleration) { tolerate_resource_class('big-disk') }
        let(:stateful)            { tolerate_resource_class('stateful') }
        let(:autopilot)           { tolerate_resource_class('autopilot') }
      end

      def tolerate_resource_class(resource_class_key)
          tolerate \
            key:      'k8s.acme.io/resource-class',
            operator: 'Equal',
            value:     resource_class_key,
            effect:    'NoSchedule'
      end
    end
  end
end

