
require 'active_support/core_ext/hash/compact'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'json'

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

      # Used to hook into ExportManifest concern
      let(:manifest)            { extracted_manifests }

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

    end
  end
end

