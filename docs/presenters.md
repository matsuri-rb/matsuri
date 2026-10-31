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
  through presenters, with no extra work.

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
