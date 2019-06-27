module Matsuri
  module Kubernetes
    class StatefulSet < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::PodTemplate
      include Matsuri::Concerns::Scalable

      let(:api_version) { 'apps/v1' }
      let(:kind)        { 'StatefulSet' } # https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

      let(:default_metadata) { { name: maybe_param_name, namespace: namespace, labels: final_labels, annotations: annotations } }

      let(:spec) do
        {
          replicas:             replicas,
          selector:             selector,
          template:             template,
          serviceName:          service_name,
          podManagementPolicy:  pod_management_policy,
          updateStrategy:       update_strategy,
          revisionHistoryLimit: revision_history_limit,
          volumeClaimTemplates: volume_claim_templates
        }.compact
      end

      # Parameters passed from command line
      # These are here to support rolling updates
      # Copied from ReplicationController, but
      # Don't know if we are going to keep this around
      let(:maybe_param_name)     { options[:name] || name }
      let(:maybe_param_replicas) { options[:relicas] || replicas }
      let(:image_tag)            { options[:image_tag] || 'latest' }

      let(:selector) { { matchLabels: match_labels, matchExpressions: match_expressions }.compact }
      let(:service_name) { fail NotImplementedError, 'Must define let(:service_name). Will define "pod-specific-string.serviceName.default.svc.cluster.local"' }

      # Explicitly define replicas
      let(:replicas)          { fail NotImplementedError, 'Must define let(:replicas)' }
      let(:match_labels)      { fail NotImplementedError, 'Must define let(:match_labels)' }
      let(:match_expressions) { nil} # Default this to nil so it drops off unless defined

      let(:revision_history_limit) { nil }

      # Deployment Strategy. Defaults to Rolling Update. Recreate is the other one.
      let(:pod_management_policy)   { fail NotImplementedError, 'Must define let(:pod_management_policy) as OrderedReady or Parallel' }
      let(:update_strategy)         { fail NotImplementedError, 'Must define let(:update_strategy). See: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies' }
      let(:on_delete_strategy)      { { type: 'OnDelete' } }
      let(:rolling_update_strategy) { { type: 'RollingUpdate', rollingUpdate: rolling_update } }
      let(:rolling_update)          { { partition: partition } }
      let(:partition)               { 0 }

      let(:volume_claim_templates)  { nil } # Make sure this is nil, otherwise stateful set cannot be updated with apply

      ### Helpers
      def volume_claim_template(name:, storage_class: nil, access_modes: 'ReadWriteOnce', storage_request:)
        {
          metadata: { name: name },
          spec: {
            accessModes: Array(access_modes),
            storageClassName: storage_class,
            resources: {
              requests: { storage: storage_request }
            }.compact
          }
        }
      end

      class << self
        def load_path
          Matsuri::Config.stateful_sets_path
        end

        def definition_module_name
          'StatefulSets'
        end
      end
    end
  end
end
