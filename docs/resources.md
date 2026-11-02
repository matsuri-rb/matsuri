# Resources

Resources are defined using `let()` extracted from `rspec` (shipped as
the `rlet` gem). Each resource has a `manifest` let that assembles the
complete resource manifest. Every value in it is constructed by a
predefined `let()` that you override with your own `let()`: the manifest
is a composition of small named values, and redefining one name changes
exactly that leaf. Values that have no sensible default — a deployment's
`replicas`, its `match_labels` — are declared holes that fail fast until
a definition fills them.

Resource definitions are Ruby classes, so inheritance can be used: a
definition can inherit from another definition and override only the
lets that differ.

You can create mixins with `Concern` that carry their own `let()`. This
allows you to include them across definitions. Matsuri comes with a few
builtin mixins:

- [`Concerns::Pods::SpreadTopology`](../lib/matsuri/concerns/pods/spread_topology.rb)
  — topology spread constraint vocabulary for balancing same-labeled
  pods across zones or nodes.
- [`Concerns::Pods::SpreadPods`](../lib/matsuri/concerns/pods/spread_pods.rb)
  — pod anti-affinity vocabulary for excluding co-location within a node
  or zone. Complements SpreadTopology: spread expresses balance,
  anti-affinity expresses exclusion.
- [`Concerns::PodTemplate`](../lib/matsuri/concerns/pod_template.rb) —
  embeds a pod definition as a workload's pod template; this is how
  Deployment, StatefulSet, and the other workloads reference pods.
- [`Concerns::ImportManifest`](../lib/matsuri/concerns/import_manifest.rb)
  — imports vendor YAML manifests as source material and transforms them
  with the same algebra.

## Defining a Resource in the Registry

Definitions live under `platform/`, one directory per resource type, one
file per definition. The registry resolves `(type, name)` to the file by
convention — `Matsuri.define :pod, 'web'` is found in
`platform/pods/web.rb`:

    platform/
      acceptors/app.rb
      config_maps/app-settings.rb
      deployments/web.rb
      pods/web.rb
      presenters/team-label.rb
      services/web.rb
      stacks/app.rb

`Matsuri.define` registers the definition and returns the class, so a
file can also refine what it defines (or define bare classes and
register them directly — the registry is the golden path, not a
requirement).

### Environments

A definition can be specialized per environment by path: the registry
consults `platform/pods/<environment>/web.rb` before
`platform/pods/web.rb`, so an environment-specific file shadows the
shared one. The environment is the CLI's first argument
(`matsuri staging ...`); see [Setup](setup.md) for how environments bind
to kubectl contexts.

See also the rspec fixture platform, which is a small, complete example
repo: [spec/fixture/platform](../spec/fixture/platform).

## Examples

### Pods

The smallest definition overrides `spec` outright:

```ruby
# platform/pods/hello.rb
Matsuri.define :pod, 'hello' do
  let(:spec) do
    { containers: [{ name: 'hello', image: 'nginx:1.25' }] }
  end
end
```

Most definitions override narrower lets and let the predefined `spec`
assemble around them:

```ruby
# platform/pods/web.rb
Matsuri.define :pod, 'web' do
  let(:container) { { name: 'web', image: "app:#{image_tag}" } }
  let(:volumes)   { [] }
end
```

Placement vocabulary (`node_selector`, `tolerations`, `affinity`,
`topology_spread_constraints`) is predefined on Pod; the spread concerns
above supply strategies for the affinity and spread lets.

See also the pod fixtures:
[spec/fixture/platform/pods](../spec/fixture/platform/pods).

### Deployments

A deployment embeds a pod definition as its template by naming it —
`let(:pod_name)` is the reference, and the pod's labels, annotations,
and spec ride in through `Concerns::PodTemplate`:

```ruby
# platform/deployments/web.rb
Matsuri.define :deployment, 'web' do
  let(:replicas)     { 2 }
  let(:match_labels) { { 'app' => 'web' } }
  let(:pod_name)     { 'web' } # embeds pod 'web' as the pod template
end
```

`replicas` and `match_labels` are declared holes — a deployment that
does not define them fails at first render, not at apply time. Rollout
knobs (`strategy`, `max_unavailable`, `max_surge`, `min_ready_seconds`)
are predefined lets with conventional defaults.

See also the deployment fixtures:
[spec/fixture/platform/deployments](../spec/fixture/platform/deployments).
