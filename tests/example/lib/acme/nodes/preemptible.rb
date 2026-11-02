# Acme set aside nodegroups that are preemptible
module Acme
  module Nodes
    module Preemptible
      extend Concern

      included do
        let(:preemptible_toleration) do
          tolerate \
            key:       'preemptible',
            operator: 'Exists',
            effect:    'NoSchedule'
        end
      end
    end
  end
end
