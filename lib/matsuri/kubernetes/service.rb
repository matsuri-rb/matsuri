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
      let(:selector) { fail NotImplementedError, 'Must define let(:selector' }

      # Commands
      def start!
        puts to_json if config.verbose
        shell_out! 'kubectl create -f -', input: to_json
      end

      def stop!
        shell_out! "kubectl delete services/#{name}"
      end

      # Helpers
      # Optional:
      #  target_port: the port exposed externally
      #  protocol:    connection protocol (ex: tcp)
      def port(num, target_port: nil, protocol: nil)
        _port = { port: num }
        _port[:targetPort] = target_port if target_port
        _port[:protocol]   = protocol    if protocol
        return _port
      end

    end
  end
end
