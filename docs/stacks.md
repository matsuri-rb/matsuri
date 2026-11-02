# Stacks

Stacks are groupings of resources that are managed together.

## Defining Stacks

Stacks are defined in `platform/stacks` with a DSL that defines
resources that are needed. It takes an argument that references a
Matsuri definition and type.

```ruby
# platform/stacks/app.rb
#
# One management promise: the app's bulkheads, the service fronting
# them, and the settings they share converge as one act, in this
# sequence.
Matsuri.define :stack, 'app' do
  needs :config_map, 'app-settings'
  needs :deployment, 'app-web'
  needs :deployment, 'app-web-streams'
  needs :deployment, 'app-worker-general'
  needs :service,    'app-web'
end
```

Each member stays independently addressable through the registry — the
stack adds sequence and shared bindings, not a new kind of resource.

At this time, there is no way to define dependencies. Applying the
manifest is performed in sequence.

## Operation

    matsuri <env> converge <stack name>

The converge operation applies changes in sequence as defined by the
stack.

## Stack Config

We can pass a configuration yaml file into the stack that can be
referenced by resources. This is intended to parameterize an entire
stack. The main use-case is to support dynamic environments used within
software development lifecycle.

```yaml
# stack-config.yaml
name: app-feat-checkout
namespace: feat-checkout
log_level: debug
expires_at: "2026-11-15"
contact: team-checkout
```

The stack declares which acceptor admits the artifact with
`accept :config`; the acceptor owns the vocabulary and the defaults (see
[Acceptors](acceptors.md)):

```ruby
# platform/acceptors/app.rb
Matsuri.define :acceptor, 'app' do
  let(:artifact) { options || {} }

  let(:instance_name) { artifact[:name] }
  let(:namespace)     { artifact[:namespace] }
  let(:log_level)     { artifact[:log_level] || 'info' }
end

# platform/stacks/app.rb
Matsuri.define :stack, 'app' do
  accept :config, 'app'

  needs :config_map, 'app-settings'
  needs :deployment, 'app-web'
  needs :service,    'app-web'
end
```

Every member resource reads the same binding through `stack_config`:

```ruby
# platform/config_maps/app-settings.rb
Matsuri.define :config_map, 'app-settings' do
  let(:data) do
    { 'LOG_LEVEL' => stack_config.log_level }
  end
end
```

The artifact rides in on the converge:

    matsuri <env> converge app --stack-config stack-config.yaml

Without the flag, every read lands on the acceptor's defaults — the
unconfigured stack behaves exactly as it did before the config surface
existed. Stack-config never crosses a stack boundary: a nested stack
reads only its own declarations.

## Server Side Apply

Stacks and resources can optionally use server side apply, in
combination with seeds.

We can also define seed presenters for stacks and resources on the
initial create. When combined with server side apply, Matsuri cedes
field management of those values. These presenters are not applied when
applying after resources are created. This allows other operators to
claim field management, while matsuri retains management over the
remaining fields.

Examples include seeded images (for deployment operators), replicas
(horizontal pod autoscaler), and resources (in-place pod autoscaling).

```ruby
# platform/deployments/app-web.rb
Matsuri.define :deployment, 'app-web' do
  let(:apply_via)    { :server_side_apply } # deliver by field ownership
  let(:replicas)     { nil }                # omitted: the autoscaler owns the count
  let(:match_labels) { { 'app' => 'web' } }
  let(:pod_name)     { 'app' }              # pod 'app' carries no image —
                                            # a deployment operator owns the tag
end

# platform/stacks/app.rb
Matsuri.define :stack, 'app' do
  needs :config_map, 'app-settings'
  needs :deployment, 'app-web'
  needs :service,    'app-web'

  present :on_create, match_deployments(seed_replicas(2))
  present :on_create, match_deployments(seed_image('registry.example.com/app:boot'))
end
```

The first converge of a server-side resource routes through the seeding
protocol (seeded create, declared apply, cede); every later apply is an
ordinary server-side apply. Converge is sequential, so a member later in
the stack converges only after an earlier member is fully seeded and
ceded. The operator walkthrough — declaring only what you manage,
conflicts, interrupted converges — is [Server-Side Apply](ssa.md); the
full model of seeds and field managers is in the Seeds section of
[Presenters](presenters.md).

See also the seed and delivery specs:
[spec/presenters/seeds_spec.rb](../spec/presenters/seeds_spec.rb) and
[spec/tasks/stacks/seed_spec.rb](../spec/tasks/stacks/seed_spec.rb).
