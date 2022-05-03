
require 'active_support/core_ext/hash/compact'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'json'

require 'awesome_print'

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/Alias
module Matsuri
  module Kubernetes
    # Some quirks about this one:
    # 1. The generated manifest is usually an array of hashes, not a hash
    # 2. It isn't generated so much as imported from a raw manifest provided by an updtream vendor
    # 3. There are helpers to transform the manifest and customize it locally
    # 4. This current version is apply-only, and does not support deletions and other operations
    class ImportedManifest < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::ImportManifest

      # Override this to run transforms
      let(:extracted_manifests) { imported_manifests }
      let(:namespace)           { Matsuri.fail "Must define let(:namespace); check the imported manifest and use the namespace found there" }

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

      # Override this to avoid triggering the normal path
      # Also, use the to_yaml transform so we can apply multiple manifest
      def apply!
        puts "Applying (create or update) imported manifest #{import_path}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        kubectl! "apply --namespace #{namespace} --record=true -f -", input: to_yaml
      end

      def create!
        Matsuri.log :fatal, "create not supported for imported manifests"
      end

      def delete!
        Matsuri.log :fatal, "delete not supported for imported manifests"
      end

      def recreate!
        Matsuri.log :fatal, "recreate not supported for imported manfiests"
      end

      def diff!
        Matsuri.log :fatal, "diff not yet supported for imported manfiest. Coming soon."
        # Implementation notes
        # Probably have to iterate through the manfiest set, look them up individually and
        # print the diff from each of those
      end

      def annotate!
        Matsuri.log :fatal, "annotate not supported for imported manifests"
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

