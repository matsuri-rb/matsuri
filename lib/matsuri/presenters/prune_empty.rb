# frozen_string_literal: true

module Matsuri
  module Presenters
    # Prunes empty values — nil, {}, [] — from the payload, bottom-up,
    # so emptiness never rides a declaration. Under server-side apply an
    # empty collection is an ownership claim over a field the definition
    # does not manage, and inside an atomic struct (.spec.selector) it
    # diverges from the server's persisted normal form, turning the
    # seeding protocol's equal-values co-ownership into a conflict. A
    # pruned payload declares in persistence normal form: ceding a field
    # and saying nothing are the same act.
    #
    # The merge is not uniformly monoidal — for some fields an empty
    # value is a genuine assertion (an atomic field held empty against
    # other writers). let(:exceptions) names those paths, each kept even
    # when empty. It ships empty; fill the let in a named definition or
    # subclass. Paths address hash keys only — they do not descend into
    # arrays.
    #
    # Empty strings are values, not emptiness ("" is meaningful to K8s —
    # storageClassName among others), and array elements are never
    # dropped — removing elements changes list semantics; only their
    # interiors prune.
    module PruneEmpty
      extend Concern

      included do
        let(:exceptions)      { [] }
        let(:exception_paths) { exceptions.map { |e| Array(e).map(&:to_s) } }
      end

      def transform(manifest)
        prune(manifest, [])
      end

      private

      def prune(value, path)
        case value
        when Hash
          value.each_with_object(value.class.new) do |(k, v), acc|
            child = prune(v, path + [k.to_s])
            acc[k] = child unless prunable?(child, path + [k.to_s])
          end
        when Array
          value.map { |v| prune(v, path) }
        else
          value
        end
      end

      def prunable?(value, path)
        return false if exception_paths.include?(path)
        value.nil? || (!value.is_a?(String) && value.respond_to?(:empty?) && value.empty?)
      end
    end
  end
end
