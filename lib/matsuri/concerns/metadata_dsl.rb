require 'active_support/concern'

module Matsuri
  module Concerns
    module MetadataDsl
      extend ActiveSupport::Concern

      included do
        attribute_accessor :labels, :annotations

        let(:metadata)            { { name: name, namespace: namespace, labels: final_labels, annotations: final_annotations } }

        let(:default_labels)      { { 'matsuri' => 'true' } }
        let(:default_annotations) { { } }

        let(:final_labels)        { default_labels.merge(labels.to_h) }
        let(:final_annotations)   { default_annotations.merge(annotations.to_h) }
      end

      def initialize_metadata_dsl
        self.labels = []
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
