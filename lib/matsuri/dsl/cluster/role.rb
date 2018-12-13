require 'rlet'

module Matsuri
  module DSL
    module Cluster
      # Cluster resources here in Matsuri are a bit different as the are meant to
      # be driven by the cluster dsl
      class Role
        include Let
        include Matsuri::Concerns::TransformManifest
        include Matsuri::DSL::Concerns::Metadata
        include Matsuri::DSL::Concerns::RbacRules
        include Matsuri::DSL::Concerns::DefaultBinding
        include Matsuri::DSL::Concerns::ManifestSet

        let(:api_version) { Matsuri::Config.rbac_api_version }
        let(:kind)        { 'Role' }

        ### Manifest Set
        let(:rbac_manifests) { [manifest, default_binding.manifest].compact }

        ### Manifest

        let(:manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    final_metadata,
            rules:       rules
          }
        end

        def initialize(options = {}, &block)
          initialize_rbac_rules_dsl
          initialize_metadata_dsl(options)

          configure(&block) if block
        end

        def configure(&block)
          instance_eval(&block)
        end
      end
    end
  end
end

