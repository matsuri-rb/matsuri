# frozen_string_literal: true

module Matsuri
  module Transform
    # Path-addressed ops over manifest data. A contribution here is a value:
    # each op takes the carrier and returns it, and pipelines compose by +
    # over those values — never by super()-chained deltas (let-bound
    # definitions cannot call super structurally, so the chained style does
    # not exist here). Ops write through Map#set; the single defensive copy
    # belongs to the Presenter boundary, not to this algebra.
    module Algebra
      extend self

      # Find a deeply nested key, and update it with the return
      # value of the transform function
      def update_in(map, path, &f)
        map.set(path, f.(map.get(path)))
      end

      def append_to(map, path, entry)
        existing = map.get(path)
        raise PathNotFound, "nothing at #{Array(path).join('.')} to append to" if existing.nil?

        map.set(path, existing + [Map.new(entry)])
      end

      # Given an array of hashes, update values in a path within
      # each element of the array using the transform function
      def update_each(arr, path, &f)
        arr.map { |term| update_in(term, path, &f) }
      end

      # Given an array of arrays, append a term to each of the arrays within
      # the array
      def append_each(a, term)
        a.map { |l| l + [term] }
      end

      def index_by_name(a, name)
        a.index { |entry| entry['name'] == name }
      end

      def index_by_name!(a, name)
        index_by_name(a, name) || raise(EntryNotFound, "no entry named #{name.inspect}")
      end

      def except_entry_by_name(arr, name:)
        arr.reject { |x| x['name'] == name }
      end
    end
  end
end
