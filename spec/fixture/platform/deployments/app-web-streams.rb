# frozen_string_literal: true

Matsuri.define :deployment, 'app-web-streams' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app_role' => 'web-streams' } }
  let(:pod_name)     { 'app' }
  let(:pod_options)  do
    default_pod_options.merge(
      app_role:    'web-streams',
      cpu_request: '1',
      mem_request: '1Gi',
      mem_limit:   '2Gi'
    )
  end
end
