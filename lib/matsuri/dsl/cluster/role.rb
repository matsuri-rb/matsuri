module Matsuri
  module DSL
    module Cluster
      # Cluster resources here in Matsuri are a bit different as the are meant to
      # be driven by the cluster dsl
      class Role
        include Matsuri::Concerns::TransformManifest

        attribute_accessor :name, :namespace, :labels, :annotations, :rules

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

        let(:metadata)            { { name: name, namespace: namespace, labels: final_labels, annotations: final_annotations } }

        let(:default_labels)      { { 'matsuri' => 'true' } }
        let(:default_annotations) { { } }

        let(:final_labels)        { default_labels.merge(labels.to_h) }
        let(:final_annotations)   { default_annotations.merge(annotations) }

        let(:resource_type)       { kind.to_s.downcase }

        def initialize(name, options = {}, &block)
          self.name = name
          self.namespace = options[:namespace]
          self.rules = []
          self.labels = []
          self.annotations = []
          configure(&block) if block
        end

        def configure(&block)
          instance_eval(&block)
        end

        def rule(api_groups: '', urls: nil, resources: nil, names: nil, verbs: nil)
          rules << {
            'apiGroups'       => api_groups,
            'nonResourceURLs' => urls,
            'resourceNames'   => names,
            'resources'       => resources,
            'verbs'           => verbs
          }.compact.map(&method(:normalize_string_array)).to_h
        end

        def resources(resources, names: nil, verbs: nil, api_groups: nil)
          rule api_groups: api_groups, resources: resources, names: names, verbs: verbs
        end

        def label(key, value)
          labels << [key, value]
        end

        def annotate(key, value)
          annotations << [key, value]
        end

        def normalize_string_array(x)
          Array(x).map(&:to_s)
        end
      end
    end
  end
end

