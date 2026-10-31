# frozen_string_literal: true

module Matsuri
  module Presenters
    # Completes a create payload with the boot replica count. Additive
    # only: a manifest that declares spec.replicas has opted out
    # structurally, and the seed yields. The including definition owns
    # what the value is: let(:replicas).
    #
    # One seed concern per presenter; compose seeds in the pipeline, not
    # by stacking includes.
    module SeedReplicas
      extend Concern

      included do
        let(:replicas) { fail NotImplementedError, 'Must define let(:replicas)' }
      end

      def transform(manifest)
        manifest.set([:spec, :replicas], replicas) if manifest.get(:spec, :replicas).nil?
        manifest
      end
    end
  end
end
