module Acme
  module Pods
    # Acme's standardized healthcheck for workloads
    # Override specific let() for legacy workloads or workloads
    # whose needs don't fit
    #
    # Usage:
    #   # in a pod definition, add:
    #   include Acme::Pods::Healthcheck
    module Healthcheck
      extend Concern

      included do
        let(:healthcheck_path) { '/healthcheck' }
        # Standard Acme port. We can be fancier and read from Acme's standard web port
        let(:healthcheck_port)                  { 8000 }
        let(:healthcheck_initial_delay_seconds) { 7 }
        let(:healthcheck_timeout_seconds)       { 1 }

        let(:readiness_probe) { healthcheck_probe }
        let(:healthcheck_probe) do
          {
            httpGet:             { path: healthcheck_path, port: healthcheck_port },
            initialDelaySeconds: healthcheck_initial_delay_seconds,
            timeoutSeconds:      healthcheck_timeout_seconds,
          }
        end

        # Acme's Elixir apps don't need liveness probes
        # However, you can add a command liveness probe to check if it
        # can still send commands to the running app
        let(:liveness_probe) { nil }
      end
    end
  end
end
