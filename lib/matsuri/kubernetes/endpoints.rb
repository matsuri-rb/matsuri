module Matsuri
  module Kubernetes
    class Endpoints < Matsuri::Kubernetes::Base
      let(:kind) { 'Endpoints' }
      let(:manifest) do
        {
          apiVersion:  api_version,
          kind:        kind,
          metadata:    final_metadata,
          subsets:     subsets
        }
      end

      # Overridables
      let(:subsets) do
        {
          addresses: addresses,
          ports: ports
        }
      end

      let(:addresses)         { [address] }
      let(:address)           { { IP: public_ip_address } }
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

    end
  end
end
