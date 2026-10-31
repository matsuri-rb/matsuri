# frozen_string_literal: true

require 'json'
require 'yaml'
require 'rlet/concern'

module Matsuri
  module Concerns
    # Mixin for K8S resources that uses pod template
    module PodTemplate
      extend Concern

      included do
        # Define this to point to an existing pod definition. This is the name
        # registered to Matsuri::Registry
        let(:pod_name) { fail NotImplementedError, 'Must define let(:pod_name)' }

        # By default, point the template to an existing pod definition
        # Overide let(:pod_name)
        let(:template) { { metadata: { labels: pod_labels, annotations: pod_annotations }, spec: pod_spec } }

        let(:pod_def)             { pod(pod_name, pod_options) }
        let(:primary_image)       { pod_def.primary_image }
        let(:primary_container)   { pod_def.primary_container }
        let(:pod_labels)          { pod_def.final_labels }
        let(:pod_annotations)     { pod_def.final_annotations }
        let(:pod_spec)            { pod_def.spec }
        let(:pod_options)         { default_pod_options }
        # Once mapped, the acceptor instance is the accepted values; the
        # template forwards it so pod definitions read the same binding the
        # owning resource holds.
        let(:default_pod_options) { { image_tag: image_tag, stack_config: stack_config } }
      end

    end
  end
end
