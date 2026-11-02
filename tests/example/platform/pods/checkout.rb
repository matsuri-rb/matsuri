# Checkout runs on its dedicated pool where one exists. The container
# carries no image and no resources: a deployment operator owns the tag
# and an in-place autoscaler owns the sizing. The stack seeds both at
# creation.
Matsuri.define :pod, 'checkout' do
  include Acme::Pods::Healthcheck

  let(:labels) { { 'app' => 'checkout' } }

  # Node selection is per-environment: local clusters have no dedicated
  # pool, so the scheduling vocabulary stays out entirely.
  case Matsuri.environment
  when 'checkout_staging'
    include Acme::Nodes::Dedicated
    let(:dedicated_key) { 'checkout' }
    let(:node_selector) { dedicated_node_selector }
    let(:tolerations)   { [dedicated_toleration] }
  end

  let(:volumes) { [] }
  let(:container) do
    {
      name:           'checkout',
      readinessProbe: readiness_probe
    }
  end
end
