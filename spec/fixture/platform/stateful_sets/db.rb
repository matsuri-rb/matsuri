Matsuri.define :stateful_set, 'db' do
  let(:replicas)              { 3 }
  let(:match_labels)          { { 'app' => 'db' } }
  let(:pod_name)              { 'db' }
  let(:service_name)          { 'db' }
  let(:pod_management_policy) { 'OrderedReady' }
  let(:update_strategy)       { rolling_update_strategy }
  let(:volume_claim_templates) do
    [volume_claim_template(name: 'data', storage_class: 'ssd', storage_request: '10Gi')]
  end
end
