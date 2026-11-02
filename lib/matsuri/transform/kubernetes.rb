# frozen_string_literal: true

module Matsuri
  module Transform
    # The Kubernetes dialect: Algebra + Env ops addressed to the manifest
    # shapes Kubernetes actually uses — container lists, env entries,
    # labels, volumes, node affinity. Well-known paths are constants so a
    # misspelled path cannot exist at a call site.
    module Kubernetes
      include Algebra
      include Env
      extend self

      NODE_SELECTOR_TERMS_PATH = %i[
        affinity
        nodeAffinity
        requiredDuringSchedulingIgnoredDuringExecution
        nodeSelectorTerms
      ].freeze

      # The pod spec within a pod-template workload or a bare pod manifest.
      def pod_spec_path(manifest)
        manifest.get(:spec, :template, :spec) ? %i[spec template spec] : %i[spec]
      end

      # Set the env variable of a container, defaults to container 0
      def set_env(spec, key, value, container: 0)
        path = [:containers, container, :env]
        spec.set(path, update_kv(spec.get(path), key, value))
      end

      # Set the env variables for all containers
      def set_all_env(spec, key, value)
        size = spec.get(:containers).length
        if size > 0 then
          (0..size - 1).inject(spec) do |spec, i|
            set_env(spec, key, value, container: i)
          end
        else
          # If there are no containers, there are other things wrong with the manifest.
          # However, return the same spec to satisify the zero-point property of the transform
          spec
        end
      end

      def set_resources(spec, resources_spec, container_name:)
        container_num = index_by_name!(spec.get(:containers), container_name)
        spec.set([:containers, container_num, :resources], resources_spec)
      end

      # Curried form of set_resources: names the container and the resource
      # spec up front, returns the spec -> spec step.
      def with_resources(name, resource_spec)
        ->(spec) { set_resources(spec, resource_spec, container_name: name) }
      end

      # Set a label
      def set_label(metadata, key, value)
        metadata.set(:labels, key, value)
      end

      # Append a volume mount to a container, defaults to container 0
      def append_volume_mount(spec, volume_mount_spec, container: 0)
        append_to(spec, [:containers, container, :volumeMounts], volume_mount_spec)
      end

      # Append a volume
      def append_volume(spec, volume_spec)
        append_to(spec, [:volumes], volume_spec)
      end

      def without_container(spec, name:)
        update_in(spec, [:containers]) { |x| except_entry_by_name(x, name: name) }
      end

      # Helper for updating node selector terms
      def update_in_node_selector_terms(spec, &f)
        update_in(spec, NODE_SELECTOR_TERMS_PATH, &f)
      end

      # Helper for updating node affinity terms
      def append_node_affinity(spec, match_expressions)
        update_in(spec, NODE_SELECTOR_TERMS_PATH) do |terms|
          terms + [match_expressions]
        end
      end
    end
  end
end
