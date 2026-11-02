# frozen_string_literal: true

module Matsuri
  module Kubernetes
    class Ingress < Matsuri::Kubernetes::Base
      let(:api_version) { 'networking.k8s.io/v1' }
      let(:kind)        { 'Ingress' }

      let(:default_annotations) { ingress_annotations }
      let(:ingress_annotations) { {} } # Reserved for ingress controller annotations

      # Overridables
      let(:spec) do
        {
          ingressClassName: ingress_class,
          defaultBackend:   default_backend,
          rules:            rules,
          tls:              tls
        }.compact
      end

      # Names an IngressClass resource; replaces the retired
      # kubernetes.io/ingress.class annotation.
      let(:ingress_class)   { nil }
      let(:default_backend) { nil }
      let(:rules)           { nil }
      let(:tls)             { nil }

      ### Helpers
      def http_rule(host:, paths:)
        { host: host, http: { paths: maybe_array(paths) } }
      end

      # pathType is required in networking.k8s.io/v1: Prefix, Exact, or
      # ImplementationSpecific. path may be omitted only for
      # ImplementationSpecific.
      def path(path = nil, service:, port:, path_type: 'Prefix')
        { path: path, pathType: path_type, backend: backend(service: service, port: port) }.compact
      end

      def backend(service:, port:)
        { service: { name: service, port: service_port(port) } }
      end

      # An Integer is a port number; anything else names a port.
      def service_port(port)
        port.is_a?(Integer) ? { number: port } : { name: port }
      end

      # Passing a hash to an array does not do this
      def maybe_array(x)
        x.is_a?(Array) ? x : [x]
      end

      class << self
        def load_path
          Matsuri::Config.ingresses_path
        end

        def definition_module_name
          'Ingresses'
        end
      end
    end
  end
end
