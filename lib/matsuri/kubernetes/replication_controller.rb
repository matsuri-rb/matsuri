
module Matsuri
  module Kubernetes
    class ReplicationController < Matsuri::Kubernetes::Base
      let(:kind) { 'ReplicationController' }

      # Overridables
      let(:spec) do
        {
          replicas: replicas,
          selector: selector,
          template: template
        }
      end

      # Explicitly define replicas
      let(:replicas) { fail NotImplementedError, 'Must define let(:replicas)' }
      let(:selector) { fail NotImplementedError, 'Must define let(:selector)' }

      # By default, point the template to an existing pod definition
      # Overide let(:pod_name)
      let(:template) { { metadata: { labels: pod_def.labels }, spec: pod_def.spec } }

      # Define this to point to an existing pod definition. This is the name
      # registered to Matsuri::Registry
      let(:pod_name) { fail NotImplementedError, 'Must define let(:pod_name)' }
      let(:pod_def)  { pod(pod_name) }
    end
  end
end
