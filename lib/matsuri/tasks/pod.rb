# frozen_string_literal: true

module Matsuri
  module Tasks
    # Pod-scoped cluster reads for the local-dev lifecycle. Resources are
    # pure generators and carry no verbs or cluster reads; this task takes
    # identity and selectors as parameters instead.
    class Pod
      include Matsuri::Task

      let(:name)      { options.fetch(:name) }
      let(:namespace) { options.fetch(:namespace) }
      let(:selector)  { options.fetch(:selector) }

      # The flat label selector addressing a resource's pods: workloads
      # (Deployment, StatefulSet, ReplicaSet, DaemonSet) declare
      # match_labels; Service declares selector. Order matters — a workload
      # also answers selector, with the nested matchLabels shape.
      def self.pod_selector_for(resource)
        return resource.match_labels if resource.respond_to?(:match_labels)
        return resource.selector     if resource.respond_to?(:selector)

        raise ArgumentError, "#{resource.class} does not select pods"
      end

      # Running, with every container ready. Reads live state by name.
      def up?
        cmd = kubectl "get pod/#{name} -o json", echo_level: :debug, no_stdout: true
        Matsuri.log :fatal, "Unable to get status for pod/#{name}" unless cmd.status.success?
        pod_json = JSON.parse(cmd.stdout)
        Matsuri.log :debug, pod_json['status']
        return false unless pod_json['status']['phase'] == 'Running'
        return false unless pod_json['status']['containerStatuses']&.any?

        pod_json['status']['containerStatuses'].all? { |c| c['ready'] == true }
      end

      # Live pods matching the label selector (a flat labels hash).
      def selected_pods_json
        sel = selector.to_a.map { |(k, v)| "#{k}=#{v}" }.join(',')
        cmd = kubectl "get pods -l #{sel} -o json", echo_level: :debug, no_stdout: true
        JSON.parse(cmd.stdout)
      end

      def selected_pods
        selected_pods_json['items']
      end

      def build!
      end

      def list!
      end
    end
  end
end
