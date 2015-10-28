
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
      let(:primary_image) { pod_def.primary_image }

      def scale!(replicas, opt={})
        puts "Scaling #{resource_type}/#{name} to #{replicas}".color(:yellow).bright if config.verbose
        kubectl! "--namespace=#{namespace} scale --replicas=#{replicas} rc #{name}"
      end

      def rollout!(image_tag, opt={})
        Matsuri.log :info, "Rolling out #{resource_type}/#{name} to #{primary_image}:#{image_tag}".color(:yellow).bright
        kubectl! "--namespace=#{namespace} rolling-update #{name} --image=#{primary_image}:#{image_tag}"
      end
    end
  end
end
