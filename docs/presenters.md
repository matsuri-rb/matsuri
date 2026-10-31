# Presenters

A presenter is one manifest-shaped step in a delivery pipeline:
`Manifest -> Manifest`. Resources stay pure generators; a presenter
transforms the rendered manifest after generation, at the delivery
boundary, before the payload is serialized for kubectl.

The promises:

- Zero-config and context-free. Construction takes nothing; every
  parameter a step needs is bound before `#call` ever runs.
- The input manifest is never mutated. `#call` is framework-owned: it
  makes one deep copy and hands it to `#transform`, so the copy is a
  constraint, not a convention an author can forget.
- The empty pipeline is the identity. A stack with no declarations sends
  payloads byte-identical to its rendered manifests.
- The diff previews the delivery. One site builds the presented payload
  for both `diff` and `apply`, so what diff shows is what apply sends —
  through presenters, with no extra work. The client-side `--hash-diff`
  reads drift against the presented declaration the same way.

## Defining Presenters

Presenters are defined in `platform/presenters`. Authors implement
`#transform` against a manifest that is already theirs to mutate, and
return it. The Kubernetes dialect (`set_env`, `set_label`,
`append_volume`, `update_in`, and friends from
`Matsuri::Transform::Kubernetes`) is bare vocabulary inside `#transform`.

```ruby
Matsuri.define :presenter, 'fluentd-sidecar' do
  def transform(manifest)
    update_in(manifest, [:spec, :template, :spec]) do |pod_spec|
      append_volume(pod_spec, name: 'varlog', emptyDir: {})
      append_to(pod_spec, [:containers],
                name:         'fluentd',
                image:        'fluentd:v1.16',
                volumeMounts: [{ name: 'varlog', mountPath: '/var/log' }])
    end
  end
end
```

As with acceptors, the registry definition is the golden path, not a
requirement: any subclass of `Matsuri::Presenter` works, and anything
`#call`-able can join a pipeline.

## Declaring Pipelines on Stacks

A stack declares its pipelines with `present`. Unlike `accept`, where a
collection names a slot and the last declaration wins, a scenario
accumulates: each `present` appends, and declaration order is member
order.

```ruby
Matsuri.define :stack, 'app' do
  needs :config_map, 'app-settings'
  needs :deployment, 'app-web'
  needs :service,    'app-web'

  present :on_apply,  match_deployments('fluentd-sidecar')
  present :on_create, 'team-label'
end
```

Members may be presenter registry names, presenter classes, `Callable`
instances, or anything `#call`-able.

### Scenarios Are Intent Regimes

Scenario names do not name kubectl verbs. There are two regimes:

- `:on_create` — bringing a resource into existence.
- `:on_apply` — delivering declared state to something that exists.

Each delivery verb assembles the pipeline for the regime it operates in:
`create` and the create leg of `recreate` assemble `:on_create`;
`apply`, `replace`, and `diff` assemble `:on_apply`. Replace is not a
third regime — `apply_via :replace` picks how the payload travels, and
the scenario picks what the payload says; the two axes stay orthogonal,
so flipping a resource's `apply_via` never changes which presenters run.
Diff is not a scenario either: its meaning is "what converge will send",
so it assembles `:on_apply` and the preview extends through presenters
for free.

Declarations never cross a stack boundary: a nested stack assembles from
its own declarations, the same rule stack-config follows.

## Declaring on Resources

A resource declares its own pipelines with the same `present` grammar;
the default is none. When a resource converges through a stack, the two
declaration sites merge into one pipeline: **resource members first,
stack members last**. These are not slot semantics — both run. Position
is about who sees the completed manifest: the resource's pipeline
completes its self-knowledge (closer to generation than to delivery),
and the stack's steps sit where the server's own mutating admission sits
relative to the client's manifest — they admit the finished product,
including whatever the resource's steps produced. Delivery-context
additions mostly commute and lose nothing by running late; a step that
enforces a boundary is only enforcement if it runs last.

Direct resource verbs (no stack context) assemble the resource's own
declarations alone, so a resource behaves identically converged directly
or through an undeclared stack.

## Selective Steps: Combinators

A stack pipeline runs across every member manifest. Combinators make a
step selective without the step knowing: `match` wraps an element and
applies it only to manifests meeting the declared
`{kind:, name:, namespace:}` criteria — the conjunction of what is
declared, the same addressing grammar imported-manifest lookup uses —
and is the identity otherwise. An unknown criteria key is an error, so a
typo cannot become match-all.

```ruby
present :on_apply, match({ kind: 'Deployment', name: 'app-web' }, 'fluentd-sidecar')
present :on_apply, match_kind('CronJob', 'team-label')
present :on_apply, match_deployments('fluentd-sidecar')
```

Combinators are machinery, not presenters: they are never registered or
named in the registry. Names cross the declaration boundary; machinery
does not.

## Parameterized Steps

Presenters take no configuration, and that is a feature: a step that
needs a value binds it before the pipeline runs, in one of three ways.

A definition fills a concern's declared hole with a `let`:

```ruby
Matsuri.define :presenter, 'app-image' do
  include MyPlatform::SeedImage          # declares let(:image) { fail ... }
  let(:image) { "registry.example.com/app:#{Matsuri::Config.image_tag}" }
end
```

A declaration closes over a one-off value in a labeled leaf:

```ruby
present :on_apply, Matsuri::Transform::Callable.new(label: 'pin-replicas') { |m|
  m.set([:spec, :replicas], 3)
}
```

Or a helper manufactures an anonymous definition — the named form minus
the registry entry, with the boundary copy riding along:

```ruby
def seed_image_presenter(image_value)
  Class.new(Matsuri::Presenter) do
    include MyPlatform::SeedImage
    let(:image) { image_value }
  end
end

present :on_create, match_deployments(seed_image_presenter('app:v12'))
```

The leaf form receives the pipeline carrier directly — a `Map` — and no
boundary copy of its own, so prefer the presenter forms for anything
reused.

## Seeds

A seed completes a create payload with a field's boot value — the
replica count, the boot image, initial resource settings — without ever
contesting a declaration. The model:

- **Additive on create.** Seeds ride `:on_create` declarations on stacks
  and resources; the ongoing `:on_apply` payload never carries them.
- **Don't-clobber is structural.** A field only seeds when the manifest
  omits it. A workload that declares `spec.replicas` has opted out — the
  seed yields, nothing overwrites. (Deployment's spec compacts, so
  `let(:replicas) { nil }` is clean omission.)
- **Controllers take ownership uncontested.** Because the create runs
  without writing the seeded fields into last-applied (`save_config`
  governs this), ongoing applies of a manifest that omits them have
  nothing to say about them — an HPA that scales is never fought. The
  cluster side of this is pinned by `tests/bin/probe-save-config.sh`.

Three concerns ship, each a machinery + declared-hole pair:
`Matsuri::Presenters::SeedReplicas` (`let(:replicas)`), `SeedImage`
(`let(:image)`, seeding only containers without one), and
`SeedResources` (`let(:resources)`, likewise). One seed concern per
presenter — compose seeds in the pipeline, not by stacking includes.
Each has a declaration-surface constructor closing the hole over its
argument:

```ruby
Matsuri.define :stack, 'app' do
  needs :deployment, 'app-web'
  needs :deployment, 'app-worker'

  present :on_create, match_deployments(seed_replicas(2))
  present :on_create, match_deployments(seed_resources(
    requests: { cpu: '500m', memory: '512Mi' }
  ))
  present :on_create, match({ kind: 'Deployment', name: 'app-worker' },
                            seed_replicas(1))
end
```

Seed values close at declaration time, so they must be literals or reads
of global state (`Matsuri::Platform`, environment config) — instance
values like the converge positional do not reach class-level
declarations.

### save_config

`save_config` feeds create/recreate's `--save-config` flag on the normal
apply path (it does not apply to server-side apply). It resolves
most-specific-first: a definition's own `let(:save_config)`, then the
owning stack's `save_config false` declaration, then the repo-wide
`Matsuri::Platform.save_config` (default `true`). Like stack-config and
`present` declarations, a stack's policy never crosses to nested stacks.

## Composition

Pipelines are `Matsuri::Transform::Callable` values: `new` is the
identity, `new(label:) { }` a leaf, `new([a, b])` a composite, and `+`
concatenates. Composition obeys the monoid laws, so bundles nest without
surprises: a composite passed as a member stays one member, and its
label rides along as trace metadata.

## What Presenters Are Not

Presenters are not the place for a resource's own vocabulary — a
deployment that always wants a label declares it in its manifest.
Presenters carry what the *delivery context* adds: the stack-wide
sidecar, the environment stamp, the value seeded only at creation.
Generation stays in definitions, delivery policy in lets
(`converge_via`, `apply_via`, `save_config`), and presentation in the
pipeline between them.
