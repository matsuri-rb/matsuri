require 'active_support/concern'

module Matsuri
  module DSL
    module Concerns
      module Metadata
        extend ActiveSupport::Concern

        included do
          attr_accessor :name, :namespace, :labels, :annotations

          let(:metadata)            { { name: name, namespace: namespace, labels: final_labels, annotations: final_annotations } }

          let(:default_labels)      { { 'matsuri' => 'true' } }
          let(:default_annotations) { { 'matsuri/source_file' => options[:source_file] }.compact } # Added for easier debugging

          let(:final_labels)        { default_labels.merge(labels.to_h) }
          let(:final_annotations)   { default_annotations.merge(annotations.to_h) }
        end

        def initialize_metadata_dsl(options = {})
          self.name        = options[:name]
          self.namespace   = options[:namespace]
          self.labels      = []
          self.annotations = []
        end

        def label(key, value)
          labels << [key, value]
        end

        def annotate(key, value)
          annotations << [key, value]
        end
      end
    end
  end
end
