# Acme CACerts
# Mount CACerts into a well-known directory
module Acme
  module Pods
    module CACerts
      extend Concern

      included do
        let(:acme_cacerts_dir)   { '/opt/acme/cacerts' }
        let(:cacerts_mount)      {  mount('cacerts-volume', acme_cacerts_dir, read_only: true) }
        let(:cacerts_volume)     { config_map_volume('cacerts-volume', config_map_name: 'cacerts') }
      end
    end
  end
end
