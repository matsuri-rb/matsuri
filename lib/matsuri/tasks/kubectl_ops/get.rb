# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Read-side of the delivery mechanism: existence checks and manifest
      # reads against the live cluster, addressed by type/name. Queries,
      # not effects, so it exposes readers instead of run!. Under verbose,
      # exists? narrates what it found.
      class Get
        include Matsuri::Task

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }

        def exists?
          cmd = kubectl "get #{resource_type}/#{name}", echo_level: :debug, no_stdout: true
          if verbose
            status = cmd.status.success? ? 'already started' : 'not started'
            Matsuri.log :info, "#{resource_type}/#{name} #{status}".color(:yellow)
          end
          cmd.status.success?
        end

        # Plain parsed hash, string keys; nil when not on the cluster.
        def manifest
          cmd = kubectl "get #{resource_type}/#{name} -o json", echo_level: :debug, no_stdout: true
          return nil unless cmd.status.success?

          JSON.parse(cmd.stdout)
        end
      end
    end
  end
end
