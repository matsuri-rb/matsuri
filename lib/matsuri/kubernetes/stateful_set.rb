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
          replicas: replicas,
          selector: selector,
          template: template,
          serviceName: service_name,
          podManagementStrategy: pod_management_strategy,
          strategy: strategy,
          revisionHistoryLimit: revision_history_limit,
          volumeClaimTemplates: volume_claim_templates
        }.compact
      end

      let(:selector) { { matchLabels: match_labels, matchExpressions: match_expressions } }
      let(:service_name) { fail NotImplementedError, 'Must define let(:service_name). Will define "pod-specific-string.serviceName.default.svc.cluster.local"' }

      # Explicitly define replicas
      let(:replicas)          { fail NotImplementedError, 'Must define let(:replicas)' }
      let(:match_labels)      { fail NotImplementedError, 'Must define let(:match_labels)' }

      let(:revision_history_limit) { nil }

      # Deployment Strategy. Defaults to Rolling Update. Recreate is the other one.
      let(:pod_management_strategy) { fail NotImplementedError, 'Must define let(:pod_management_strategy) as OrderedReady or Parallel' }
      let(:strategy)                { fail NotImplementedError, 'Must define let(:strategy). See: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies' }
      let(:on_delete_strategy)      { { type: 'OnDelete' } }
      let(:rolling_update_strategy) { { type: 'RollingUpdate', rollingUpdate: rolling_update } }
      let(:rolling_update)          { { partition: partition } }
      let(:partition)               { 0 }

      let(:volume_claim_templates)  { [] }

      let(:match_expressions) { [] }

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
