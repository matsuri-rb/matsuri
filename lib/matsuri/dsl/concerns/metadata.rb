require 'active_support/concern'

module Matsuri
  module DSL
    module Concerns
      module Metadata
        extend ActiveSupport::Concern

        included do
          attr_accessor :labels, :annotations, :options

          let(:name)           { options[:name] }
          let(:namespace)      { options[:namespace] || parent_scope[:namespace] }
          let(:source_file)    { parent_scope[:source_file] }
          let(:skip?)          { options[:skip] || parent_scope[:skip] }

          let(:parent_scope)   { options[:scoped_options] || {} }

          let(:scoped_options) do
            {
              namespace:   namespace,
              source_file: source_file,
              skip:        skip?
            }
          end

          let(:metadata)            { { name: name, namespace: namespace, labels: final_labels, annotations: final_annotations } }
          let(:default_labels)      { { 'matsuri/dsl' => 'cluster/v1' } }
          let(:default_annotations) { { 'matsuri/source_file' => source_file }.compact } # Added for easier debugging
          let(:final_labels)        { default_labels.merge(labels.to_h) }
          let(:final_annotations)   { default_annotations.merge(annotations.to_h) }
        end

        def initialize_metadata_dsl(options = {})
          self.options     = options
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
