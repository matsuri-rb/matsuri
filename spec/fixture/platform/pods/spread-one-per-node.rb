Matsuri.define :pod, 'spread-one-per-node' do
  include Matsuri::Concerns::Pods::SpreadPods

  let(:labels)            { { 'app_role' => 'spread-one-per-node' } }
  let(:pod_anti_affinity) { schedule_one_per_node }

  let(:cpu_limit)   { '100m' }
  let(:mem_limit)   { '128Mi' }
  let(:volumes)     { [] }
  let(:container)   { { name: 'worker', image: 'worker:latest', resources: resources } }
end
