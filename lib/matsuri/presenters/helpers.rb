# frozen_string_literal: true

module Matsuri
  module Presenters
    # Declaration-surface constructors: each closes a seed concern's hole
    # over its argument as an anonymous Presenter subclass — the named
    # definition form minus the registry entry, with the boundary copy
    # riding along.
    module Helpers
      def seed_replicas(count)
        Class.new(Matsuri::Presenter) do
          include Matsuri::Presenters::SeedReplicas
          let(:replicas) { count }
        end
      end

      def seed_image(image_value)
        Class.new(Matsuri::Presenter) do
          include Matsuri::Presenters::SeedImage
          let(:image) { image_value }
        end
      end

      def seed_resources(resources_spec)
        Class.new(Matsuri::Presenter) do
          include Matsuri::Presenters::SeedResources
          let(:resources) { resources_spec }
        end
      end

      def prune_empty(except: [])
        Class.new(Matsuri::Presenter) do
          include Matsuri::Presenters::PruneEmpty
          let(:exceptions) { except }
        end
      end
    end
  end
end
