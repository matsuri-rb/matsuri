Matsuri.define :deployment, 'billing-web' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app' => 'billing' } }
  let(:pod_name)     { 'billing' }
end
