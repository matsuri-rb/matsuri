# frozen_string_literal: true

module Matsuri
  module Concerns
    # The import surface: locating a vendor manifest file, extracting
    # documents from it, and the set-carrier lookups that address manifests
    # within a stream by {kind, name, namespace}. The transform vocabulary
    # (set_env, append_volume, update_in, and friends) comes from
    # Matsuri::Transform::Kubernetes, included here, so local customization
    # of imported manifests uses the same dialect as presenters.
    module ImportManifest
      extend Concern

      included do
        include Matsuri::Transform::Kubernetes

        let(:import_path)           { fail NotImplementedError, 'Must define let(:import_path)' }

        ### Override
        let(:imported_metadata)     { imported_pod_metadata }
        let(:imported_labels)       { final_metadata.get(:labels) }

        let(:imported_pod_metadata) { imported_manifest.get(:spec, :template, :metadata) }
        let(:imported_pod_spec)     { imported_manifest.get(:spec, :template, :spec) }
        let(:imported_manifest)     { Map.new(YAML.load_file(full_import_path)) }
        let(:full_import_path)      { File.join(Matsuri::Config.imported_manifests_path, import_path)}

        # Support for finding and extracting a manifest from a stream (multiple yaml documents in a file)
        # Override with:
        # let(:imported_manifest) { extracted_manifest }
        # let(:import_filter_criteria) { { kind: "Something", name: "something", namespace: "something" }}

        let(:extracted_manifest)     { Map.new(lookup_manifests(imported_manifests, import_filter_criteria).first) }
        let(:imported_manifests)     { YAML.load_stream(File.read(full_import_path)) }
        let(:import_filter_criteria) { fail NotImplementedError, 'Must define let(:import_filter_criteria)' }
      end

      # Assumes that the complex key of {kind, name, namespace} is unique within a given set of manifests
      def lookup_manifests(set, criteria)
        raise ArgumentError, "Must pass name: and kind: for criteria" unless criteria[:kind] && criteria[:name]
        set.select(&criteria_matcher(criteria))
      end

      # This is used when we have a collection of manifests, more useful for importing a bundle
      # using Matsuri::Kubernetes::ImportedManifest (importing raw manifests from a vendor upstream)
      def without_manifest(set, criteria)
        raise ArgumentError, "Must pass name: and kind: for criteria" unless criteria[:kind] && criteria[:name]

        set.reject(&criteria_matcher(criteria))
      end

      def criteria_matcher(criteria)
        ->(hash) { matches_criteria?(hash, criteria) }
      end

      def matches_criteria?(hash, criteria)
        h = Map.new(hash)
        h.get(:kind) == criteria[:kind] &&
          h.get(:metadata, :name) == criteria[:name] &&
          (criteria[:namespace] == nil || h.get(:metadata, :namespace) == criteria[:namespace])
      end
    end
  end
end
