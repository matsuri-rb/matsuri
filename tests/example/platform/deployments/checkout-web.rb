Matsuri.define :deployment, 'checkout-web' do
  let(:apply_via)    { :server_side_apply } # deliver by field ownership
  let(:replicas)     { nil }                # omitted: the autoscaler owns the count
  let(:match_labels) { { 'app' => 'checkout' } }
  let(:pod_name)     { 'checkout' }
end
