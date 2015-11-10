
module Matsuri
  module Kubernetes
    class ReplicationController < Matsuri::Kubernetes::Base
      let(:kind) { 'ReplicationController' }

      # Overridables

      let(:default_metadata) { { name: maybe_param_name, namespace: namespace, labels: final_labels, annotations: annotations } }
      let(:default_labels)   { { 'app-name' => name } } # Needed for autodetecting 'current' for rolling-updates
      let(:final_labels)     { default_labels.merge(labels) }

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
        current_rc = current_rc_name
        next_rc    = "#{name}-#{image_tag}"

        Matsuri.log :info, "Current replication controller: #{current_rc}"
        Matsuri.log :info, "Next replication controller: #{next_rc}"
        Matsuri.log :info, "Rolling out #{resource_type}/#{name} to #{primary_image}:#{image_tag}".color(:yellow).bright

        # Create a next controller, overriding image tag, name, and replicas
        # Start replicas with 1 and move from there.
        rc_next = rc(name, name: next_rc, image_tag: image_tag, replicas: 1)
        #rc_next.start!

        kubectl! "--namespace=#{namespace} rolling-update #{current_rc} #{name}-#{image_tag} -f -", input: rc_next.to_json
      end

      def current_rc_name
        cmd = kubectl "--namespace=#{namespace} get #{resource_type}/#{name}-#{image_tag}", no_stdout: true
        return name if cmd.status.success?

        # Fallback to using selector
        Matsuri.log :info, "Unable to find #{name}. Searching for rc with label app-name=#{name}"

        cmd = kubectl "--namespace=#{namespace} get #{resource_type} --selector='app-name=#{name}' -o json", no_stdout: true
        Matsuri.log :fatal, "Unable to find a replication controller with label app-name=#{name}" unless cmd.status.success?
        resp = parse_json(cmd)

        Matsuri.log :fatal, "Unable to find a replication controller with label app-name=#{name}" if resp['items'].empty?

        if resp['items'].size == 1
          return resp['items'][0]['metadata']['name']
        else
          Matsuri.log :fatal, "Multiple replication controllers found with label app-name=#{name}. Not yet supported"
        end
      end

      private
      def parse_json(cmd)
        JSON.parse(cmd.stdout)
      end
    end
  end
end
