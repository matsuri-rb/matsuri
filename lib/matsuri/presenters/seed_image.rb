# frozen_string_literal: true

module Matsuri
  module Presenters
    # Completes a create payload with the boot image on every container
    # that does not carry one. Additive only: a container that declares
    # its image has opted out structurally, and the seed yields. The
    # including definition owns what the value is: let(:image).
    #
    # One seed concern per presenter; compose seeds in the pipeline, not
    # by stacking includes.
    module SeedImage
      extend Concern

      included do
        let(:image) { fail NotImplementedError, 'Must define let(:image)' }
      end

      def transform(manifest)
        containers = manifest.get(*pod_spec_path(manifest), :containers) || []
        containers.each do |container|
          container.set(:image, image) if container[:image].nil?
        end
        manifest
      end
    end
  end
end
