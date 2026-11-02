# Checkout runs on its dedicated pool. The container carries no image
# and no resources: a deployment operator owns the tag and an in-place
# autoscaler owns the sizing. The stack seeds both at creation.
Matsuri.define :pod, 'checkout' do
  include Acme::Pods::Healthcheck
  include Acme::Nodes::Dedicated

  let(:dedicated_key) { 'checkout' }
  let(:labels)        { { 'app' => 'checkout' } }
  let(:node_selector) { dedicated_node_selector }
  let(:tolerations)   { [dedicated_toleration] }

  let(:volumes) { [] }
  let(:container) do
    {
      name:           'checkout',
      readinessProbe: readiness_probe
    }
  end
end
