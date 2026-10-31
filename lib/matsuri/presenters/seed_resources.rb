# frozen_string_literal: true

module Matsuri
  module Presenters
    # Completes a create payload with boot resource settings on every
    # container that does not carry its own. Additive only: a container
    # that declares resources has opted out structurally, and the seed
    # yields. The including definition owns what the value is:
    # let(:resources).
    #
    # One seed concern per presenter; compose seeds in the pipeline, not
    # by stacking includes.
    module SeedResources
      extend Concern

      included do
        let(:resources) { fail NotImplementedError, 'Must define let(:resources)' }
      end

      def transform(manifest)
        containers = manifest.get(*pod_spec_path(manifest), :containers) || []
        containers.each do |container|
          container.set(:resources, resources) if container[:resources].nil?
        end
        manifest
      end
    end
  end
end
