Matsuri.define :deployment, 'app-web-streams' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app_role' => 'web-streams' } }
  let(:pod_name)     { 'app' }
  let(:pod_options)  do
    default_pod_options.merge(
      app_role: 'web-streams',
      requests: { cpu: '1',   memory: '1Gi' },
      limits:   { memory: '2Gi' }
    )
  end
end
