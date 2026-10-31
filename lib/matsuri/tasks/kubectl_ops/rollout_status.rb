# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Watches a workload's rollout to completion (kubectl rollout
      # status) — the post-apply progress watch for manually delivered
      # changes. Blocks until the rollout finishes or fails.
      class RolloutStatus
        include Matsuri::Task

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }

        def run!
          kubectl! "rollout status #{resource_type}/#{name}"
        end
      end
    end
  end
end
