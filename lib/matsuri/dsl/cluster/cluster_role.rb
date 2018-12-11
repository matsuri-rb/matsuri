module Matsuri
  module DSL
    module Cluster
      # Cluster resources here in Matsuri are a bit different as the are meant to
      # be driven by the cluster dsl
      class ClusterRole < Matsuri::DSL::Cluster::Role
        let(:kind)        { 'ClusterRole' }

        let(:manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    final_metadata,
            rules:       rules
          }
        end

        # Cluster Roles are not namespaced. Override from MetadataDsl concern
        let(:metadata) { { name: name, labels: final_labels, annotations: final_annotations } }

        ### DSL Helper

        # Use these to add urls to the rules
        # nonResourceURLs apply only to ClusterRoles
        def urls(urls, verbs: nil, api_groups: nil)
          rule api_groups: api_groups, urls: urls, verbs: verbs
        end
      end
    end
  end
end

