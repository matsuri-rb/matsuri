Matsuri.define :deployment, 'app-worker-general' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app_role' => 'worker', 'resource_class' => 'general' } }
  let(:pod_name)     { 'app' }
  let(:pod_options)  { default_pod_options.merge(app_role: 'worker', resource_class: 'general') }
end
