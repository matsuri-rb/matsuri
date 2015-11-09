
module Matsuri
  module Kubernetes
    class ReplicationController < Matsuri::Kubernetes::Base
      let(:kind) { 'ReplicationController' }

      # Overridables

      let(:default_metadata) { { name: maybe_param_name, namespace: namespace, labels: labels, annotations: annotations } }
      let(:spec) do
        {
          replicas: replicas,
          selector: selector,
          template: template
        }
      end

      # Parameters passed from command line
      # These are here to support rolling updates
      let(:maybe_param_name)     { options[:name] || name }
      let(:maybe_param_replicas) { options[:relicas] || replicas }
      let(:image_tag)            { options[:image_tag] || 'latest' }

      # Explicitly define replicas
      let(:replicas) { fail NotImplementedError, 'Must define let(:replicas)' }
      let(:selector) { fail NotImplementedError, 'Must define let(:selector)' }

      # By default, point the template to an existing pod definition
      # Overide let(:pod_name)
      let(:template) { { metadata: { labels: pod_def.labels }, spec: pod_def.spec } }

      # Define this to point to an existing pod definition. This is the name
      # registered to Matsuri::Registry
      let(:pod_name) { fail NotImplementedError, 'Must define let(:pod_name)' }
      let(:pod_def)  { pod(pod_name, image_tag: image_tag) }
      let(:primary_image) { pod_def.primary_image }

      def scale!(replicas, opt={})
        puts "Scaling #{resource_type}/#{name} to #{replicas}".color(:yellow).bright if config.verbose
        kubectl! "--namespace=#{namespace} scale --replicas=#{replicas} rc #{name}"
      end

      def rollout!(image_tag, opt={})
        Matsuri.log :info, "Rolling out #{resource_type}/#{name} to #{primary_image}:#{image_tag}".color(:yellow).bright

        # Create a next controller, overriding image tag, name, and replicas
        # Start replicas with 1 and move from there.
        #rc_next = rc(name, name: "#{name}-#{image_tag}", image_tag: image_tag, replicas: 1)
        #rc_next.start!

        kubectl! "--namespace=#{namespace} rolling-update #{name} #{name}-#{image_tag} --image=#{primary_image}:#{image_tag}"
        return if started?

        # Some versions of kubectl does not support renaming after rollout
        # Get latest version of RC from server
        cmd = kubectl "--namespace=#{namespace} get #{resource_type}/#{name}-#{image_tag} -o json", no_stdout: true
        Matsuri.log :fatal, "Unable to rename #{name}-#{image_tag}\n#{cmd.stdout}\n#{cmd.stderr}" unless cmd.status.success?
        json_def = JSON.parse(cmd.stdout)
        json_def['metadata']['name'] = name

        kubectl! "--namespace=#{namespace} create -f -", input: JSON.generate(json_def)
        stop!
        Matsuri.log :info, "Renamed #{name}-#{image_tag} to #{name}"
      end

    end
  end
end
