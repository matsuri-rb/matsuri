# Diff

Matsuri carries two diffs because there are two different questions to
ask before a converge, and no single comparison answers both.

**The server-side diff** (the default) answers: *what will the cluster
actually do with this manifest?* The payload — the exact payload `apply`
would send — is dry-run through the apiserver, where defaulting and
admission controllers run, and kubectl prints live-vs-admitted. If an
admission controller injects a sidecar, a default, or a label, it shows
here.

**The hash diff** (`--hash-diff`) answers: *how has the live object
drifted from my declaration?* The comparison runs locally against the
rendered manifest, and everything the cluster owns — `status`, the
last-applied annotation, server-populated defaults, equivalent
quantities like `1024Mi` vs `1Gi` — is filtered out, so what remains is
your drift, not the cluster's bookkeeping.

Use the default to preview a converge; use `--hash-diff` when the
admitted view drowns your one-line change in injected fields.

## Usage

```console
$ matsuri staging diff deployment web            # server-side: live vs admitted
$ matsuri staging diff deployment web --hash-diff # client-side: drift vs declaration
$ matsuri staging diff stack my-stack            # every member, same flags
```

Workload resource verbs accept an image tag positional, same as apply:

```console
$ matsuri staging diff deployment web v1.2.3
```

## Primary container focus

`-p` / `--primary-container` narrows the comparison to the first
container of the pod template — the usual question being "did anything
but my image change?":

```console
$ matsuri staging diff deployment web v1.2.3 -p
```

The projection is a hash-diff affordance (kubectl has no equivalent), so
`-p` implies `--hash-diff`.

Every built-in workload with a pod template declares where its primary
container lives via `let(:primary_container_path)`; a custom resource
that wants `-p` declares the path into its own manifest shape:

```ruby
let(:primary_container_path) { ['spec', 'template', 'spec', 'containers', 0] }
```

## Exit codes

The server-side diff inherits kubectl's convention:

- `0` — no differences (and no output; silence means clean)
- `1` — differences found (not an error)
- above `1` — an actual failure

## Tuning the hash diff filters

The noise filters live on the resource (`Matsuri::Concerns::Diffable`),
so a definition that knows about additional cluster-owned paths can
override them:

```ruby
Matsuri.define :deployment, 'web' do
  # a controller rewrites this annotation on every sync; never report it
  def always_changed_path?(path)
    super || path == 'metadata.annotations.example.com/sync-stamp'
  end
end
```

The filter surface: `readonly_path?` (paths the apiserver owns),
`always_changed_path?` (values rewritten on every apply),
`default_value_assigned_nothing?` (declaring a default the server
already holds), and `unit_comparison_is_equal?` (quantity-aware
equality). Each returning `true` suppresses that comparison.
