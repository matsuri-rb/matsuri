require 'active_support/concern'

module Matsuri
  module DSL
    module Concerns
      # Defines the callbacks for being able to generate a ManifestSet
      module ManifestSet
        extend ActiveSupport::Concern

        included do
          # By default, return nil. This will exclude the manifest from being generated
          # To include a manifest, override it with something like let(:rbac_manifest) { manifest }
          let(:rbac_manifests)    { nil }
          let(:cluster_manifests) { nil }
        end
      end
    end
  end
end
