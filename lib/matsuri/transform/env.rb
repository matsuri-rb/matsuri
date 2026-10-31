# frozen_string_literal: true

module Matsuri
  module Transform
    # The array <-> map isomorphism for container env entries. Manifests
    # carry env as an ordered array of {name:, value:|valueFrom:} entries;
    # the map side exists so entries can be updated by key. The round trip
    # preserves order, appends new keys at the end, and compacts duplicate
    # names (last write wins), so it is not a 1-to-1 mapping.
    module Env
      extend self

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

      def expand_env(hash)
        hash.map do |k, v|
          if v.is_a?(Hash)
            { name: k, valueFrom: v }
          else
            { name: k, value: v.to_s }
          end
        end
      end
    end
  end
end
