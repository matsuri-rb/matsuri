# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Scales a live workload addressed by type/name.
      class Scale
        include Matsuri::Task

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }
        let(:replicas)      { options.fetch(:replicas) }

        def run!
          Matsuri.log :info, "Scaling #{resource_type}/#{name} to #{replicas}".color(:yellow).bright
          kubectl! "scale --replicas=#{replicas} #{resource_type}/#{name}"
        end
      end
    end
  end
end
