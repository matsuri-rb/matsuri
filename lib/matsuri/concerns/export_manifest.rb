require 'active_support/concern'

module Matsuri
  module Concerns
    module ExportManifest
      extend ActiveSupport::Concern

      included do

        let(:core_manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    metadata
          }
        end

        let(:manifest)         { fail NotImplementedError, 'Must define let(:manifest)' }

        # Some resources only allow certain fields to be applied. Override this
        # to restrict it.
        let(:applied_manifest) { manifest }

        let(:api_version) { fail NotImplementedError, 'Must define let(:api_version)' }
        let(:kind)        { fail NotImplementedError, 'Must define let(:kind)' }
        let(:metadata)    { { } }
        let(:name)        { fail NotImplementedError, 'Must define let(:name)' }
        let(:spec)        { fail NotImplementedError, 'Must define let(:spec)' }
      end

      def to_json
        manifest.to_json
      end

      def to_yaml
        manifest.deep_stringify_keys.to_yaml
      end

      def applied_to_json
        applied_manifest.to_json
      end

      def applied_to_yaml
        applied_manifest.deep_stringify_keys.to_yaml
      end

      def pretty_print
        JSON.pretty_generate(manifest)
      end
    end
  end
end
