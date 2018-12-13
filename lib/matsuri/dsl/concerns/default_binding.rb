require 'active_support/concern'

module Matsuri
  module DSL
    module Concerns
      module DefaultBinding
        extend ActiveSupport::Concern

        included do
          let(:default_binding) { Matsuri::DSL::Cluster::Binding.new(default_binding_options) }

          let(:default_binding_name)      { name }      # Use the name of the role or cluster_role
          let(:default_binding_namespace) { namespace } # Use the namespace of the role
          let(:default_binding_type)      { kind }

          let(:default_binding_options) do
            {
              name:      default_binding_name,
              namespace: default_binding_namespace,
              type:      default_binding_type
            }
          end
        end

        def bind_to(name, kind:, namespace: nil)
          default_binding.subject(name, kind: kind, namespace: namespace || self.namespace)
        end
      end
    end
  end
end
