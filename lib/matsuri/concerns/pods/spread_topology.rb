# frozen_string_literal: true

require 'rlet/concern'

module Matsuri
  module Concerns
    module Pods
      # Topology spread constraint vocabulary for balancing same-labeled pods
      # across topology domains. Not included in Pod by default; include it in
      # a definition and select a strategy:
      #
      #   include Matsuri::Concerns::Pods::SpreadTopology
      #   let(:topology_spread_constraints) { balance_across_zones }
      #
      # Strategies return lists, so they compose by concatenation:
      #
      #   let(:topology_spread_constraints) { balance_across_zones + balance_across_nodes }
      #
      # Complements Concerns::Pods::SpreadPods: spread constraints express
      # balance (bounded skew of replica counts per domain), anti-affinity
      # expresses exclusion (no co-location within a domain). Definitions
      # commonly carry both — zone balance here, node exclusion there.
      # zone_topology_key is the same noun in both concerns, so one override
      # re-points both mechanisms.
      module SpreadTopology
        extend Concern

        included do
          let(:topology_spread_constraints) { fail NotImplementedError, 'define let(:topology_spread_constraints) required' }

          ### Strategies: one builder, specialized by topology key
          let(:balance_across_zones) { [balanced_spread(zone_topology_key, max_skew: zone_max_skew, when_unsatisfiable: zone_when_unsatisfiable)] }
          let(:balance_across_nodes) { [balanced_spread(node_topology_key, max_skew: node_max_skew, when_unsatisfiable: node_when_unsatisfiable)] }

          ### Topology keys
          let(:zone_topology_key)    { 'topology.kubernetes.io/zone' }
          let(:node_topology_key)    { 'kubernetes.io/hostname' }

          ### Knob ladder: shared default, per-domain override
          let(:spread_max_skew)           { 1 }
          let(:spread_when_unsatisfiable) { 'ScheduleAnyway' }

          let(:zone_max_skew)             { spread_max_skew }
          let(:zone_when_unsatisfiable)   { spread_when_unsatisfiable }
          let(:node_max_skew)             { spread_max_skew }
          let(:node_when_unsatisfiable)   { spread_when_unsatisfiable }

          let(:spread_label_selector)     { label_selector(match_labels: spread_labels) }
          let(:spread_labels)             { labels }
        end

        def balanced_spread(topology_key, max_skew: spread_max_skew, when_unsatisfiable: spread_when_unsatisfiable)
          topology_spread_constraint(
            topology_key:       topology_key,
            max_skew:           max_skew,
            when_unsatisfiable: when_unsatisfiable,
            label_selector:     spread_label_selector
          )
        end
      end
    end
  end
end
