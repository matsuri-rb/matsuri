Matsuri.define :deployment, 'web' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app' => 'web' } }
  let(:pod_name)     { 'web' }
end
