require 'json'
require 'yaml'
require 'active_support/concern'

module Matsuri
  module Concerns
    # Mixin for K8S resources that uses pod template
    module PodTemplate
      extend ActiveSupport::Concern

      included do
        # Define this to point to an existing pod definition. This is the name
        # registered to Matsuri::Registry
        let(:pod_name) { fail NotImplementedError, 'Must define let(:pod_name)' }

        # By default, point the template to an existing pod definition
        # Overide let(:pod_name)
        let(:template) { { metadata: { labels: pod_labels, annotations: pod_annotations }, spec: pod_spec } }

        let(:pod_def)           { pod(pod_name, image_tag: image_tag, release: release) }
        let(:primary_image)     { pod_def.primary_image }
        let(:primary_container) { pod_def.primary_container }
        let(:pod_labels)        { pod_def.final_labels }
        let(:pod_annotations)   { pod_def.final_annotations }
        let(:pod_spec)          { pod_def.spec }
      end

      ### Helpers
      def selected_pods_json
        fail NotImpelmentedError, 'Match Expressions not yet implemented' if Array(match_expressions).any?
        sel = match_labels.to_a.map { |(k,v)| "#{k}=#{v}" }.join(',')
        cmd = kubectl "get pods -l #{sel} -o json", echo_level: :debug, no_stdout: true
        JSON.parse(cmd.stdout)
      end

      def selected_pods
        selected_pods_json['items']
      end
    end
  end
end
