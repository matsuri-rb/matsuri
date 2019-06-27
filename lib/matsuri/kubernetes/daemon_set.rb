module Matsuri
  module Kubernetes
    class DaemonSet < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::PodTemplate

      let(:api_version) { 'apps/v1' }   # K8S 1.10
      let(:kind)        { 'DaemonSet' } # http://kubernetes.io/docs/user-guide/deployments/

      # Overridables
      let(:spec) do
        {
          selector:             selector,
          template:             template,
          minReadySeconds:      min_ready_seconds,
          revisionHistoryLimit: revision_history_limit,
          updateStrategy:       update_strategy
        }.compact
      end

      let(:selector) { { matchLabels: match_labels, matchExpressions: match_expressions } }

      # Parameters
      let(:image_tag) { options[:image_tag] || 'latest' }

      # Explicitly define replicas
      let(:match_labels)      { fail NotImplementedError, 'Must define let(:match_labels)' }
      let(:match_expressions) { [] }

      # Update strategy
      # See: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#rollingupdatedaemonset-v1-app
      let(:update_strategy) { { type: 'RollingUpdate', rollingUpdate: rolling_update } }
      let(:rolling_update)  { { maxUnavailable: max_unavailable } }
      let(:max_unavailable) { 1 }

      # Minimum number of seconds for which a newly created pod should be ready without
      # any of its container crashing, for it to be considered available.
      # Defaults to 0 (pod will be considered available as soon as it is ready)
      let(:min_ready_seconds) { 0 }

      # The number of old ReplicaSets to retain to allow rollback. This is a pointer to
      # distinguish between explicit zero and not specified.
      let(:revision_history_limit) { nil }

      ### Helpers

      ### Matsuri Registry
      class << self
        def load_path
          Matsuri::Config.daemon_sets_path
        end

        def definition_module_name
          'DaemonSets'
        end
      end
    end
  end
end
