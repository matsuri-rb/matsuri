# Setup

## A Matsuri Repo

The minimal skeleton:

    Gemfile                 # pins the matsuri version (and plugins)
    bin/matsuri             # wrapper: pins the bundle, nothing else
    config/
      matsuri.rb            # marks the repo base; Config overrides
      platform.rb           # environment definitions
      initializer.rb        # loads plugins and your library
    lib/                    # your organization's extension library
    platform/               # resource definitions

`config/matsuri.rb` is the marker: matsuri finds the repo by walking up
from the working directory until it sees one. A working example repo
lives in [tests/example](../tests/example). How the pieces load — the
wrapper, the environment argument, the initializer — is covered in
[Boot](boot.md).

## Environments and kubectl Contexts

Every kubectl command matsuri runs is scoped to a context and a
namespace:

    kubectl --context=<context> --namespace=<namespace> ...

The namespace comes from the environment's platform config (default
`default`). The context comes from one of two modes.

## Default Mode: the Environment Name Is the Context Name

By default, matsuri assumes a kubeconfig context exists with the same
name as the environment: `matsuri staging converge myapp` runs
`kubectl --context=staging ...`. Cluster tools hand out longer names —
GKE contexts look like `gke_myproject_us-central1_staging` — so matsuri
provides a verb that binds the environment's name as an alias:

```bash
matsuri staging kubectl setup
```

This runs `kubectl config set-context staging` with the cluster, user,
and namespace drawn from the environment's platform config:

```ruby
# config/platform.rb
require 'map'

staging Map.new(
  namespace:    'myapp',
  kube_cluster: 'gke_myproject_us-central1_staging',
  user:         'gke_myproject_us-central1_staging'
)
```

`kube_cluster` and `user` default to the environment name when not
given; `namespace` defaults to `default`.

Setup is a one-time step per environment, and it only creates the alias:
the cluster and user entries it points at must already exist in your
kubeconfig. Get them from your provider first — for example
`gcloud container clusters get-credentials`, or `minikube start` /
`k3d cluster create`, which write their own entries. Local tools often
already name their context something usable (`minikube`,
`k3d-mycluster`), in which case name your environment to match and skip
setup entirely.

## Mapped Mode: Point the Environment at an Existing Context

If you would rather not alias — letting `gcloud` own authentication and
context naming, for instance — set `map_env_to_kube_context` and name
the real context in platform config:

```ruby
# config/matsuri.rb
map_env_to_kube_context true
```

```ruby
# config/platform.rb
staging Map.new(
  namespace:    'myapp',
  kube_context: 'gke_myproject_us-central1_staging'
)
```

With this set, every environment must define `kube_context`;
`kubectl setup` is unnecessary in this mode.

## Verifying

```bash
kubectl config get-contexts     # the environment (or mapped) context exists
matsuri staging status pods     # matsuri reaches the cluster through it
```
