module Matsuri
  module Kubernetes
    class Service < Matsuri::Kubernetes::Base
      let(:kind) { 'Service' }

      # Overridables
      let(:spec) do
        {
          ports: ports,
          selector: selector
        }
      end

      let(:ports)    { [port(port_num)] }
      let(:port_num) { fail NotImplementedError, 'Must define let(:port_num)' }
      let(:selector) { fail NotImplementedError, 'Must define let(:selector)' }

      # Helpers
      # Optional:
      #  target_port: the port exposed externally
      #  protocol:    connection protocol (ex: tcp)
      def port(num, target_port: nil, protocol: nil, name: nil)
        _port = { port: num }
        _port[:targetPort] = target_port   if target_port
        _port[:protocol]   = protocol.to_s if protocol
        _port[:name]       = name.to_s     if name
        return _port
      end

    end
  end
end
