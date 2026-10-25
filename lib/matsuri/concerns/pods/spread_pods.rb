# frozen_string_literal: true

require 'rlet/concern'

module Matsuri
  module Concerns
    module Pods
      # Pod anti-affinity vocabulary for spreading pods that share the same
      # labels across nodes or zones. Not included in Pod by default; include
      # it in a definition and select a strategy:
      #
      #   include Matsuri::Concerns::Pods::SpreadPods
      #   let(:pod_anti_affinity) { schedule_one_per_zone }
      #
      module SpreadPods
        extend Concern

        included do
          let(:pod_anti_affinity)          { fail NotImplementedError, 'define let(:pod_anti_affinity) required' }

          let(:schedule_one_per_node)      { required_during_scheduling(other_pods_of_type_in_node) }
          let(:schedule_one_per_zone)      { required_during_scheduling(other_pods_of_type_in_zone) }

          # preferredDuringScheduling entries must be weighted terms
          let(:prefer_one_per_node)        { preferred_during_scheduling(weighted_other_pods_of_type_in_node) }
          let(:prefer_one_per_zone)        { preferred_during_scheduling(weighted_other_pods_of_type_in_zone) }

          let(:other_pods_of_type_in_node) { pod_affinity_term match_labels: anti_affinity_labels }
          let(:other_pods_of_type_in_zone) { pod_affinity_term match_labels: anti_affinity_labels, topology_key: zone_topology_key }

          let(:weighted_other_pods_of_type_in_node) { weighted_pod_affinity_term match_labels: anti_affinity_labels, weight: spread_weight }
          let(:weighted_other_pods_of_type_in_zone) { weighted_pod_affinity_term match_labels: anti_affinity_labels, weight: spread_weight, topology_key: zone_topology_key }

          let(:spread_weight)              { 100 }

          # Well-known topology label, set by the cloud provider on GKE and
          # EKS alike. Its deprecated predecessor,
          # failure-domain.beta.kubernetes.io/zone, is no longer applied to
          # nodes.
          let(:zone_topology_key)          { 'topology.kubernetes.io/zone' }

          let(:anti_affinity_labels)       { labels }
        end
      end
    end
  end
end
