# frozen_string_literal: true

module Matsuri
  module Kubernetes
    class ReplicaSet < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::PodTemplate

      let(:api_version) { 'apps/v1' }    # K8S 1.10
      let(:kind)        { 'ReplicaSet' } # http://kubernetes.io/docs/user-guide/replicasets/

      # Overridables

      let(:spec) do
        {
          replicas: replicas,
          selector: selector,
          template: template
        }
      end

      let(:selector) { { matchLabels: match_labels, matchExpressions: match_expressions } }

      # Supplied by the owning stack through dep_options, or by the CLI
      # positional; pod templates read it.
      let(:image_tag) { options[:image_tag] }

      # Explicitly define replicas
      let(:replicas)          { fail Matsuri::UndefinedLet, 'Must define let(:replicas)' }
      let(:match_labels)      { fail Matsuri::UndefinedLet, 'Must define let(:match_labels)' }

      let(:match_expressions) { [] }

      let(:primary_container_path) { ['spec', 'template', 'spec', 'containers', 0] }

      class << self
        def load_path
          Matsuri::Config.replica_sets_path
        end

        def definition_module_name
          'ReplicaSets'
        end
      end
    end
  end
end
