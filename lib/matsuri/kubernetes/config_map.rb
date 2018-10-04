require 'base64'

module Matsuri
  module Kubernetes
    class ConfigMap < Matsuri::Kubernetes::Base
      let(:api_version) { 'v1' }    # K8S 1.10
      let(:kind)        { 'ConfigMap' }

      # Overridables
      let(:manifest) do
        {
          apiVersion: api_version,
          kind:       kind,
          metadata:   final_metadata,
          data:       data,
          binaryData: binary_data
        }
      end

      let(:data)         { nil }
      let(:binary_data)  { nil }

      # Helpers

      # Binary Files must be Base64 Encoded. This load the secret from
      # disk (default: config/securets/)  base64 encode it.
      def binary_from(path)
        binary_from_path(config_overlays_path(path))
      end

      # Load secret file and base64 encode it from any file location
      def binary_from_path(path)
        base64(File.read(path))
      end

      def text_from(path)
        text_from_path(config_overlays_path(path))
      end

      def text_from_path(path)
        File.read(path)
      end

      # Helper to load secrets file from default location
      def config_overlays_path(path)
        File.join(Matsuri::Config.config_overlays_path, path)
      end

      # Helper for base64 encoder. This allows us to pull
      # secrets from elsewhere, such as from Hashicorp Vault
      # or from an encrypted AWS S3 bucket item
      def base64(file)
        Base64.encode64(file).split("\n").join # Strip all newlines
      end

      # Helper to transform the values of a hash to base64
      def base64_hash(hash)
        Hash[hash.map { |k,v| [k, base64(v) ] }]
      end

      ### Overrides

      # kubectl current does not support applying configmaps. Best is to create and replace
      # See: https://github.com/kubernetes/kubernetes/issues/32432
      #      https://github.com/kubernetes/kubernetes/issues/41711
      # Do not save config (force replace)
      def create!
        puts "Creating #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        kubectl! 'create -f -', input: to_json
      end

      # Apply does not really work with ConfigMaps. Best use replace instead.
      def apply!
        puts "Replace #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        kubectl! 'replace -f -', input: applied_to_json
      end

      # Secrets are not generally something passed around in developer copies
      # These are things set up by the cluster administrator, so we can assume
      # if it is present on the server, we can skip it. As such, better to use
      # recreate than apply for secrets.
      def converge!(opts = {})
        converge_by_recreate!(opts)
      end

      class << self
        def load_path
          Matsuri::Config.config_maps_path
        end

        def definition_module_name
          'Configmaps'
        end
      end
    end
  end
end
