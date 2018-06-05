require 'active_support/core_ext/hash/compact'

module Matsuri
  module Kubernetes
    class Service < Matsuri::Kubernetes::Base
      let(:api_version) { 'v1' }    # K8S 1.10
      let(:kind)        { 'Service' }

      # Overridables
      let(:spec) do
        {
          ports:     ports,
          selector:  selector,
          type:      service_type,
          clusterIP: cluster_ip
        }.compact
      end

      let(:ports)        { [port(port_num)] }
      let(:port_num)     { fail NotImplementedError, 'Must define let(:port_num)' }
      let(:selector)     { fail NotImplementedError, 'Must define let(:selector)' }
      let(:service_type) { 'ClusterIP' }
      let(:cluster_ip)   { nil }

      # Helpers
      # Optional:
      #  target_port: the port exposed externally
      #  protocol:    connection protocol (ex: tcp)
      def port(num, target_port: nil, protocol: nil, name: nil, node_port: nil)
        _port = { port: num }
        _port[:targetPort] = target_port   if target_port
        _port[:nodePort]   = node_port     if node_port
        _port[:protocol]   = protocol.to_s if protocol
        _port[:name]       = name.to_s     if name
        return _port
      end

      ### @TODO Refactor to Selectable concern
      ### Helpers
      def selected_pods_json
        sel = selector.to_a.map { |(k,v)| "#{k}=#{v}" }.join(',')
        cmd = kubectl "get pods -l #{sel} -o json", echo_level: :debug, no_stdout: true
        JSON.parse(cmd.stdout)
      end

      def selected_pods
        selected_pods_json['items']
      end

      class << self
        def load_path
          Matsuri::Config.services_path
        end

        def definition_module_name
          'Services'
        end
      end
    end
  end
end
