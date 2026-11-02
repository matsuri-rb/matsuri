# frozen_string_literal: true

require 'matsuri/core_ext'
require 'json'

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/Alias
module Matsuri
  module Kubernetes
    # Some quirks about this one:
    # 1. The generated manifest is usually an array of hashes, not a hash
    # 2. It isn't generated so much as imported from a raw manifest provided by an upstream vendor
    # 3. There are helpers to transform the manifest and customize it locally
    # 4. Apply-only: the CLI binds no other verb for imported manifests
    class ImportedManifest < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::ImportManifest

      # Override this to run transforms; the Transform::Kubernetes dialect
      # is in scope (set_env, update_in, append_volume, ...)
      let(:extracted_manifests) { imported_manifests }
      let(:namespace)           { fail Matsuri::UndefinedLet, "Must define let(:namespace); check the imported manifest and use the namespace found there" }

      # Identity for delivery messages; there is no single kind to derive it from
      let(:resource_type)       { 'imported manifest' }

      # Used to hook into ExportManifest concern
      let(:manifest_for_export)         { normalize_manifests(extracted_manifests) }
      let(:applied_manifest_for_export) { normalize_manifests(extracted_manifests) }

      def normalize_manifests(manifests)
        Array(manifests).map(&:deep_stringify_keys)
      end

      # Don't return a yaml array. Return a concated set of yaml files
      def to_yaml
        manifest_for_export.
          map(&:to_yaml).
          join('')
      end

      def applied_to_yaml
        applied_manifest_for_export.
          map(&:to_yaml).
          join('')
      end

      ### Matsuri Registry
      class << self
        def load_path
          Matsuri::Config.imported_manifests_path
        end

        def definition_module_name
          'ImportedManifests'
        end
      end

    end
  end
end

