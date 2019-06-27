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
            metadata:    metadata,
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

        # Helper to aggregate cluster role to admin, edit, view, and other similar tags
        def aggregate_to(*tags)
          tags.flatten.each do |tag|
            label "rbac.authorization.k8s.io/aggregate-to-#{tag}", 'true'
          end
        end
      end
    end
  end
end

