require "base64"

module Matsuri
  module Kubernetes
    class Secret < Matsuri::Kubernetes::Base
      let(:kind) { 'Secret' }

      # Overridables
      let(:spec) do
        {
          type: secret_type,
          data: data
        }
      end

      # Looks like Kubernetes 1.0.6 supports only Opaque secrets
      let(:secret_type) { 'Opaque' }
      let(:data) { { secret_key => secret_value } }

      let(:secret_key)   { fail NotImplementedError, 'Must define let(:secret_key)' }
      let(:secret_value) { secret_from(secret_path) }

      # Helpers

      # Secrets must be Base64 Encoded. This load the secret from
      # disk (default: config/secrets) and base64 encode it.
      def secret_from(path)
        secret_from_path(File.join(Matsuri::Config.config_secrets_path, path))
      end

      # This will load secret from any path without assuming
      # that it is in the secret path
      def secret_from_path(path)
        base64(File.read(path))
      end

      # Helper for base64 encoder. This allows us to pull
      # secrets from elsewhere, such as from Hashicorp Vault
      # or from an encrypted AWS S3 bucket item
      def base64(secret)
        Base64.encode64(secret)
      end

    end
  end
end
