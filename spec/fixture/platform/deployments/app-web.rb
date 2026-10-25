# frozen_string_literal: true

Matsuri.define :deployment, 'app-web' do
  let(:replicas)     { 4 }
  let(:match_labels) { { 'app_role' => 'web' } }
  let(:pod_name)     { 'app' }
  let(:pod_options)  { default_pod_options.merge(app_role: 'web') }
end
