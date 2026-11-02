# Server-side delivery: matsuri manages the fields it declares and
# cedes the rest. The seeds complete the create payload only — the
# first converge routes through the seeding protocol (seeded create,
# declared apply, cede), then the deployment operator takes the image,
# the HPA takes the count, and the in-place autoscaler takes sizing.
Matsuri.define :stack, 'checkout' do
  needs :deployment, 'checkout-web'
  needs :service,    'checkout-web'

  present :on_create, match_deployments(seed_replicas(2))
  present :on_create, match_deployments(seed_image('registry.acme.io/checkout:boot'))
  present :on_create, match_deployments(seed_resources(requests: { cpu: '250m', memory: '256Mi' }))
end
