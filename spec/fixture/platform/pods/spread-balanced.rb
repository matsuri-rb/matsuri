# One-per-node exclusion via anti-affinity, zone balance via topology
# spread constraints: the two mechanisms composed.
Matsuri.define :pod, 'spread-balanced' do
  include Matsuri::Concerns::Pods::SpreadPods
  include Matsuri::Concerns::Pods::SpreadTopology

  let(:labels) { { 'app_role' => 'spread-balanced' } }

  let(:pod_anti_affinity)           { prefer_one_per_node }
  let(:topology_spread_constraints) { balance_across_zones }

  let(:cpu_limit)   { '100m' }
  let(:mem_limit)   { '128Mi' }
  let(:volumes)     { [] }
  let(:container)   { { name: 'worker', image: 'worker:latest', resources: resources } }
end
