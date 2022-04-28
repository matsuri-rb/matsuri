module Matsuri
  module Concerns
    module ImportManifest
      extend ActiveSupport::Concern

      included do
        let(:import_path)           { fail NotImplementedError, 'Must define let(:import_path)' }

        ### Override
        let(:imported_metadata)     { imported_pod_metadata }
        let(:imported_labels)       { final_metadata.get(:labels) }

        let(:imported_pod_metadata) { imported_manifest.get(:spec, :template, :metadata) }
        let(:imported_pod_spec)     { imported_manifest.get(:spec, :template, :spec) }
        let(:imported_manifest)     { Map.new(YAML.load_file(full_import_path)) }
        let(:full_import_path)      {   File.join(Matsuri::Config.platform_path, 'manifests', import_path)}

        # Support for finding and extracting a manifeest from a stream (multiple yaml documents in a file)
        # Override with:
        # let(:imported_manifest) { extracted_manifest }
        # let(:import_filter_criteria) { { kind: "Something", name: "something", namespace: "something" }}

        let(:extracted_manifest)     { Map.new(lookup_manifests(imported_manifests, import_filter_criteria).first) }
        let(:imported_manifests)     { YAML.load_stream(File.read(full_import_path)) }
        let(:import_filter_criteria) { fail NotImplementedError, 'Must define let(:import_filter_criteria)' }

        let(:with_resources) { ->(name, resource_spec) { ->(spec) { set_resources(spec, resource_spec, container_name: name) } } }

        let(:node_selector_terms_path) do
          [
            :affinity,
            :nodeAffinity,
            :requiredDuringSchedulingIgnoredDuringExecution,
            :nodeSelectorTerms
          ]
        end

      end

      # Assumes that the complex key of {kind, name, namespace} is unique within a given set of manifests
      def lookup_manifests(set, criteria)
        raise ArgumentError, "Must pass name: and kind: for criteria" unless criteria[:kind] && criteria[:name]
        set.select(&method(:criteria_matcher))
      end

      # This is used when we have a collection of manifests, more useful for importing a bundle
      # using Matsuri::Kubernetes::ImportedManifest (importing raw manifests from a vendor upstream)
      def without_manifest(set, criteria)
        raise ArgumentError, "Must pass name: and kind: for criteria" unless criteria[:kind] && criteria[:name]

        set.reject(&method(:criteria_matcher))
      end


      def criteria_matcher(hash)
        h = Map.new(hash)
        h.get(:kind) == criteria[:kind] &&
          h.get(:metadata, :name) == criteria[:name] &&
          (criteria[:namespace] == nil || h.get(:metadata, :namespace) == criteria[:namespace])
      end


      def without_container(spec, name:)
        update_in(spec, [:containers]) { |x|  except_entry_by_name(x, name: name) }
      end

      # Set a label
      def set_label(metadata, key, value)
        metadata.set(:labels, key, value)
      end

      # Set the env variable of a container, defaults to container 0
      def set_env(spec, key, value, container: 0)
        path = [:containers, container, :env]
        spec.set(path, update_kv(spec.get(path), key, value))
      end

      def set_resources(spec, resources_spec, container_name:)
        container_num = index_by_name(spec.get(:containers), container_name)
        raise "Unable to find container_name #{container_name.inspect} in container spec" if container_num.nil?

        spec.set([:containers, container_num, :resources], resources_spec) #.tap { |x| puts x.inspect }
      end

      # Set the env variables for all containers
      def set_all_env(spec, key, value)
        size = spec.get(:containers).length
        if size > 0 then
          (0..size-1).inject(spec) do |spec, i|
            set_env(spec, key, value, container: i)
          end
        else
          # If there are no containers, there are other things wrong with the manifest.
          # However, return the same spec to satisify the zero-point property of the transform
          spec
        end
      end

      # Append a volume mount to a container, defaults to container 0
      def append_volume_mount(spec, volume_mount_spec, container: 0)
        append_to(spec, [:containers, container, :volumeMounts], volume_mount_spec)
      end

      # Append a volume
      def append_volume(spec, volume_spec)
        append_to(spec, [:volumes], volume_spec)
      end

      # Helper for updating node selector terms
      def update_in_node_selector_terms(spec, &f)
        update_in(spec, node_selector_terms_path, &f)
      end

      # Helper for updating node affinity terms
      def append_node_affinity(spec, match_expressions)
        update_in(spec, node_slector_terms_path) do |terms|
          terms + [match_expressions]
        end
      end

      # Find a deeply nested key, and update it with the return
      # value of the transform function
      def update_in(map, path, &f)
        map.set(path, f.(map.get(path)))
      end

      def append_to(map, path, entry)
        map.set(path, map.get(path) + [Map.new(entry)])
      end

      # Given an array of hashes, update values in a path within
      # each element of the array using the transform function
      def update_each(arr, path, &f)
        arr.map { |term| update_in(term, path, &f) }
      end

      def except_entry_by_name(arr, name:)
        arr.reject { |x| x['name'] == name }
      end

      # This updates an env by transforming it into an ordered hash (ahoward/map), doing the hash
      # update, and then converting back into an array of hashes.
      # This is inefficient for large entries, however, manfiests usually don't have a large
      # set of kv. This will update existing entries, append new entries, and preserve order
      # It will also compact any duplicates, so it is not produce a 1-to-1 mapping
      def update_kv(kv, key, value)
        updated_kv = env_to_map(kv).update(key, value)
        expand_env(updated_kv)
      end

      def env_to_map(kv)
        kv.inject(Map.new) do |acc, entry|
          case
          when entry.key?('value')
            acc[entry['name']] = entry['value']
          when entry.key?('valueFrom')
            acc[entry['name']] = entry['valueFrom']
          else
            nil
          end
          acc
        end
      end


      # Given an array of arrays, append a term to each of the arrawy within
      # the array
      def append_each(a, term)
        a.map { |l| l + [term] }
      end

      def index_by_name(a, name)
        a.index { |entry| entry['name'] == name }
      end

    end
  end
end
