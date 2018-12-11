module Matsuri
  module DSL
    module Cluster
      # Cluster resources here in Matsuri are a bit different as the are meant to
      # be driven by the cluster dsl
      class Role
        include Matsuri::Concerns::TransformManifest
        include Matsuri::Concerns::RbacRulesDsl
        include Matsuri::Concerns::MetadataDsl

        attribute_accessor :name, :namespace

        # @TODO - Break out base into mixins that could be used elsewhere
        # This way, we're can put this back into Matsuri::DSL::Role
        # Since these are meant to be driven by the DSL rather than defined
        # individually like the other K8S resources

        let(:api_version) { Matsuri::Config.rbac_api_version }
        let(:kind)        { 'Role' }

        let(:manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    final_metadata,
            rules:       rules
          }
        end

        def initialize(name, options = {}, &block)
          self.name = name
          self.namespace = options[:namespace]

          initialize_rbac_rules_dsl
          initialize_metadata_dsl

          configure(&block) if block
        end

        def configure(&block)
          instance_eval(&block)
        end
      end
    end
  end
end

