require "base64"

module Matsuri
  module Kubernetes
    class Secret < Matsuri::Kubernetes::Base
      let(:kind) { 'Secret' }

      # Overridables
      let(:manifest) do
        {
          apiVersion: api_version,
          kind:       kind,
          metadata:   final_metadata,
          type:       secret_type,
          data:       data
        }
      end

      # Looks like Kubernetes 1.0.6 supports only Opaque secrets
      let(:secret_type) { 'Opaque' }
      let(:data) { { secret_key => secret_value } }

      let(:secret_key)   { fail NotImplementedError, 'Must define let(:secret_key)' }
      let(:secret_value) { secret_from_path(full_secret_path) }
      let(:secret_path)  { fail NotImplementedError, 'Must define let(:secret_path)' }

      let(:full_secret_path) { secret_file(secret_path) }

      # Override let(:data) with yaml_data if the secret file is
      # in yaml form
      let(:yaml_data)   { base64_hash(yaml_secret) }
      let(:yaml_secret) { YAML.load_file(secret_file(secret_path)) }

      # Helpers

      # Secrets must be Base64 Encoded. This load the secret from
      # disk (default: config/securets/)  base64 encode it.
      def secret_from(path)
        secret_from_path(secret_file(path))
      end

      # Load secret file and base64 encode it from any file location
      def secret_from_path(path)
        base64(File.read(path))
      end

      # Helper to load secrets file from default location
      def secret_file(path)
        File.join(Matsuri::Config.config_secrets_path, path)
      end

      # Helper for base64 encoder. This allows us to pull
      # secrets from elsewhere, such as from Hashicorp Vault
      # or from an encrypted AWS S3 bucket item
      def base64(secret)
        Base64.encode64(secret)
      end

      # Helper to transform the values of a hash to base64
      def base64_hash(hash)
        Hash[hash.map { |k,v| [k, base64(v) ] }]
      end

      ### Overrides

      # Secrets are not generally something passed around in developer copies
      # These are things set up by the cluster administrator, so we can assume
      # if it is present on the server, we can skip it. As such, better to use
      # recreate than apply for secrets.
      def converge!(opts = {})
        converge_by_recreate!(opts)
      end

      class << self
        def load_path
          Matsuri::Config.secrets_path
        end

        def definition_module_name
          'Secrets'
        end
      end
    end
  end
end
