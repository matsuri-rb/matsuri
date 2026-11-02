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

  # Both regimes declare in persistence normal form: an empty value is a
  # ceded field, never an ownership claim, so the create's echo equals
  # the declaration and co-ownership holds.
  present :on_create, prune_empty
  present :on_apply,  prune_empty
end
