
module Matsuri
  module Kubernetes
    class ReplicationController < Matsuri::Kubernetes::Base
      let(:kind) { 'ReplicationController' }

      # Overridables

      let(:default_metadata) { { name: maybe_param_name, namespace: namespace, labels: final_labels, annotations: annotations } }
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
      let(:template) { { metadata: { labels: pod_def.labels, annotations: pod_def.annotations }, spec: pod_def.spec } }

      # Define this to point to an existing pod definition. This is the name
      # registered to Matsuri::Registry
      let(:pod_name) { fail NotImplementedError, 'Must define let(:pod_name)' }
      let(:pod_def)  { pod(pod_name, image_tag: image_tag, release: release) }
      let(:primary_image) { pod_def.primary_image }

      def status!
        current_rc = current_rc_name
        puts "Current rc name: #{current_rc}"
        puts "Current image_tag: #{current_image_tag(current_rc)}"
      end

      def scale!(replicas, opt={})
        current_rc = current_rc_name

        Matsuri.log :info, "Scaling #{resource_type}/#{current_rc} to #{replicas}".color(:yellow).bright
        kubectl! "--namespace=#{namespace} scale --replicas=#{replicas} rc #{current_rc}"
      end

      def rollout!(image_tag, opt={})
        current_rc = current_rc_name
        next_rel   = release_number(current_rc) + 1
        next_rc    = "#{name}-r#{next_rel}"

        image_tag = current_image_tag(current_rc) unless image_tag

        Matsuri.log :info, "Current replication controller: #{current_rc}"
        Matsuri.log :info, "Next replication controller: #{next_rc}"
        Matsuri.log :info, "Rolling out #{resource_type}/#{name} to #{primary_image}:#{image_tag}".color(:yellow).bright

        # Create a next controller, overriding image tag, name, and replicas
        # Start replicas with 1 and move from there.
        rc_next = rc(name, name: next_rc, release: next_rel, image_tag: image_tag, replicas: 1)
        #rc_next.start!

        Matsuri.log(:debug) { rc_next.pretty_print }
        kubectl! "--namespace=#{namespace} rolling-update #{current_rc} #{next_rc} -f -", input: rc_next.to_json
      end

      def current_rc_name
        cmd = kubectl "--namespace=#{namespace} get #{resource_type}/#{name}", echo_level: :debug, no_stdout: true
        return name if cmd.status.success?

        # Fallback to using selector
        Matsuri.log :info, "Unable to find #{name}. Searching for rc with label matsuri-name=#{name}"

        cmd = kubectl "--namespace=#{namespace} get #{resource_type} --selector='matsuri-name=#{name}' -o json", echo_level: :debug, no_stdout: true
        Matsuri.log :fatal, "Unable to find a replication controller with label matsuri-name=#{name}" unless cmd.status.success?
        resp = parse_json(cmd)

        Matsuri.log :fatal, "Unable to find a replication controller with label matsuri-name=#{name}" if resp['items'].empty?

        if resp['items'].size == 1
          return resp['items'][0]['metadata']['name']
        else
          Matsuri.log :fatal, "Multiple replication controllers found with label matsuri-name=#{name}. Not yet supported"
        end
      end

      def current_image_tag(rc_name)
        cmd = kubectl "--namespace=#{namespace} get #{resource_type}/#{rc_name} -o json", echo_level: :debug, no_stdout: true
        Matsuri.log :fatal, "Unable to find #{resource_type}/#{rc_name}" unless cmd.status.success?
        resp = parse_json(cmd)

        image_name = resp['spec']['template']['spec']['containers'][0]['image']
        Matsuri.log :info, "Found primary image: #{image_name}"
        image_tag = extract_image_tag(image_name)

        if image_tag.empty?
          Matsuri.log :warn, "Unable to extract image tag from #{image_name}"
        else
          Matsuri.log :info, "Current image tag: #{image_tag}"
        end

        return image_tag
      end

      private
      def parse_json(cmd)
        JSON.parse(cmd.stdout)
      end

      def extract_image_tag(image_name)
        image_name =~ /:(.*)$/ ? $1 : ''
      end

      # Extract release number from the name
      def release_number(k8s_name)
        k8s_name =~ /-r(\d+)$/ ? ($1).to_i : 0
      end

      class << self
        def load_path
          Matsuri::Config.rcs_path
        end

        def definition_module_name
          'ReplicationControllers'
        end
      end
    end
  end
end
