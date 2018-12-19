require 'active_support/core_ext/hash/compact'

module Matsuri
  module Kubernetes
    class Ingress < Matsuri::Kubernetes::Base
      let(:api_version) { 'extensions/v1beta1' }    # K8S 1.10
      let(:kind)        { 'Ingress' }

      let(:default_annotations) do
        {
          'kubernetes.io/ingress.class' => ingress_class
        }.merge(ingress_annotations).compact
      end

      let(:ingress_annotations) { {} } # Reserved for ingress controller annotations

      # Overridables
      let(:spec) do
        {
          backend:   default_backend,
          rules:     rules,
          tls:       tls
        }.compact
      end

      let(:default_backend) { nil }
      let(:rules)           { nil }
      let(:tls)             { nil }

      # Annotations
      let(:ingress_class)   { nil }

      ### Helpers
      def http_rule(host:, paths:)
        { host: host, http: { paths: maybe_array(paths) } }
      end

      def path(path = nil, service:, port:)
        # Path may be unspecified, and thus all paths will be routed to this backend
        # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#httpingresspath-v1beta1-extensions
        { path: path, backend: backend(service: service, port: port) }.compact
      end

      def backend(service:, port:)
        { serviceName: service, servicePort: port }
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
