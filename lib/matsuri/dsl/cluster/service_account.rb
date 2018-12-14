require 'rlet'

module Matsuri
  module DSL
    module Cluster
      # Cluster resources here in Matsuri are a bit different as the are meant to
      # be driven by the cluster dsl
      class ServiceAccount
        include Let
        include Matsuri::Concerns::TransformManifest
        include Matsuri::DSL::Concerns::Metadata
        include Matsuri::DSL::Concerns::ManifestSet

        attr_accessor :manifest_config

        let(:api_version) { 'core/v1' }
        let(:kind)        { 'ServiceAccount' }

        ### Manifest Set
        let(:manifests) { manifest }

        ### Manifest

        let(:manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    final_metadata,

            automountServiceAccountToken: manifest_config[:automount_token],
            imagePullSecrets:             manifest_config[:image_pull_secrets],
            secrets:                      manifest_config[:secrets]
          }.compact
        end

        def initialize(options = {}, &block)
          initialize_metadata_dsl(options)
          self.manifest_config = {
            automount_token:    nil,
            image_pull_secrets: [],
            secrets:            []
          }

          configure(&block) if block
        end

        def configure(&block)
          instance_eval(&block)
        end

        ### DSL Helpers
        def automount_token(flag = true)
          manifest_config[:automount_token] = flag
        end

        def image_pull_secret(name)
          manifest_config[:image_pull_secret] << { name: name }
        end

        # Usually the name is sufficient.
        def secret(name, options = {})
          manifest_config[:secret] << {
            name: name,
            namespace:       options[:namespace],
            apiVersion:      options[:api_version],
            kind:            options[:kind],
            resourceVersion: options[:version],
            uid:             options[:uid]
          }.compact
        end
      end
    end
  end
end
