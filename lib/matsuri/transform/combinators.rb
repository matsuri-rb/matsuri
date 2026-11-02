# frozen_string_literal: true

module Matsuri
  module Transform
    # Combinators are Element -> Element: they take a transform step and
    # return a transform step, so selectivity lives in the wrapper and the
    # wrapped element stays total. They are machinery, not presenters —
    # never registry-named; names cross the declaration boundary, machinery
    # does not.
    module Combinators
      # Applies its element only to manifests meeting the criteria —
      # identity otherwise. Criteria are the conjunction of the declared
      # {kind:, name:, namespace:} constraints, the same addressing grammar
      # import lookup uses; an undeclared key constrains nothing, an unknown
      # key is an error.
      class Match
        CRITERIA_KEYS = %w[kind name namespace].freeze

        attr_reader :criteria, :element

        def initialize(criteria, element)
          @criteria = Map.new(criteria)
          unknown = @criteria.keys - CRITERIA_KEYS
          raise ArgumentError, "unknown match criteria #{unknown.inspect}; use #{CRITERIA_KEYS.join(', ')}" if unknown.any?

          @element = Callable.new([element])
        end

        def call(manifest)
          return manifest unless matches?(manifest)

          element.call(manifest)
        end

        def matches?(manifest)
          m = Map === manifest ? manifest : Map.new(manifest)
          (criteria[:kind].nil?      || m.get(:kind) == criteria[:kind]) &&
            (criteria[:name].nil?      || m.get(:metadata, :name) == criteria[:name]) &&
            (criteria[:namespace].nil? || m.get(:metadata, :namespace) == criteria[:namespace])
        end
      end

      # The declaration-surface vocabulary. Sugars grow on demand.
      module Helpers
        def match(criteria, element)
          Match.new(criteria, element)
        end

        def match_kind(kind, element)
          Match.new({ kind: kind }, element)
        end

        def match_deployments(element)
          match_kind('Deployment', element)
        end
      end

      extend Helpers
    end
  end
end
