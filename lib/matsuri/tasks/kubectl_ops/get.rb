# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Read-side of the delivery mechanism: existence checks against the
      # live cluster, addressed by type/name. Queries, not effects, so it
      # exposes predicates instead of run!.
      class Get
        include Matsuri::Task

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }

        def exists?
          cmd = kubectl "get #{resource_type}/#{name}", echo_level: :debug, no_stdout: true
          cmd.status.success?
        end
      end
    end
  end
end
