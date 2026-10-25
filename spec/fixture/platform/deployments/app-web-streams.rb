Matsuri.define :deployment, 'app-web-streams' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app_role' => 'web', 'resource_class' => 'streams' } }
  let(:pod_name)     { 'app' }
  let(:pod_options)  { default_pod_options.merge(app_role: 'web', resource_class: 'streams') }
end
