Matsuri.define :pod, 'spread-worker' do
  include Matsuri::Concerns::Pods::SpreadPods

  let(:labels)            { { 'app_role' => 'spread-worker' } }
  let(:pod_anti_affinity) { schedule_one_per_zone }

  let(:cpu_limit)   { '100m' }
  let(:mem_limit)   { '128Mi' }
  let(:volumes)     { [] }
  let(:container)   { { name: 'worker', image: 'worker:latest', resources: resources } }
end
