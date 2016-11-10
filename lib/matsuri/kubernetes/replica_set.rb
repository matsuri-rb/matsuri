module Matsuri
  module Kubernetes
    class ReplicaSet < Matsuri::Kubernetes::Base
      let(:api)  { 'extensions/v1beta1' } # http://kubernetes.io/docs/api-reference/extensions/v1beta1/definitions/#_v1beta1_replicaset
      let(:kind) { 'ReplicaSet' }         # http://kubernetes.io/docs/user-guide/replicasets/

      # Overridables

      let(:default_metadata) { { name: maybe_param_name, namespace: namespace, labels: final_labels, annotations: annotations } }
      let(:spec) do
        {
          replicas: replicas,
          selector: selector,
          template: template
        }
      end

      let(:selector) { { matchLabels: match_labels, matchExpressions: match_expressions } }

      # Parameters passed from command line
      # These are here to support rolling updates
      # Don't know if we are going to keep this around
      let(:maybe_param_name)     { options[:name] || name }
      let(:maybe_param_replicas) { options[:relicas] || replicas }
      let(:image_tag)            { options[:image_tag] || 'latest' }

      # Explicitly define replicas
      let(:replicas)          { fail NotImplementedError, 'Must define let(:replicas)' }
      let(:match_labels)      { fail NotImplementedError, 'Must define let(:match_labels)' }

      let(:match_expressions) { [] }

      # By default, point the template to an existing pod definition
      # Overide let(:pod_name)
      let(:template) { { metadata: { labels: pod_def.labels, annotations: pod_def.annotations }, spec: pod_def.spec } }

      # Define this to point to an existing pod definition. This is the name
      # registered to Matsuri::Registry
      let(:pod_name) { fail NotImplementedError, 'Must define let(:pod_name)' }
      let(:pod_def)  { pod(pod_name, image_tag: image_tag, release: release) }
      let(:primary_image) { pod_def.primary_image }

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
