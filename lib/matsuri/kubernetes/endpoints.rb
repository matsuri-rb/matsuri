module Matsuri
  module Kubernetes
    class Endpoints < Matsuri::Kubernetes::Base
      let(:api_version) { 'v1' }    # K8S 1.10
      let(:kind)        { 'Endpoints' }
      let(:manifest) do
        {
          apiVersion:  api_version,
          kind:        kind,
          metadata:    final_metadata,
          subsets:     subsets
        }
      end

      # Overridables
      let(:subsets) { [subset] }
      let(:subset) do
        {
          addresses: addresses,
          ports: ports
        }
      end

      let(:addresses)         { [localhost, address] }
      let(:localhost)         { { ip: '127.0.0.1' } }
      let(:address)           { { ip: public_ip_address, targetRef: target_ref } }
      let(:target_ref)        { fail NotImplementedError, 'Must define let(:target_ref)' }

      let(:ports)             { [port(port_num)] }
      let(:public_ip_address) { config.dev_addr }
      let(:port_num)          { fail NotImplementedError, 'Must define let(:port_num)' }
      let(:port_proto)        { 'tcp' }

      # Helpers
      # Optional:
      #  target_port: the port exposed externally
      #  protocol:    connection protocol (ex: tcp)
      def port(num, protocol: 'TCP', name: nil)
        _port = { port: num, protocol: protocol.to_s }
        _port[:name] = name.to_s if name
        return _port
      end

      class << self
        def load_path
          Matsuri::Config.endpoints_path
        end

        def definition_module_name
          'Endpoints'
        end
      end
    end
  end
end
