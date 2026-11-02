# Example Matsuri Repo

A working Matsuri platform repo. It boots against the minikube test
cluster, and it showcases the layout a real repo follows (see
docs/setup.md in the matsuri repo): a Gemfile pinning the matsuri
version, a `bin/matsuri` wrapper, config, an org extension library
(`lib/acme`), and resource definitions under `platform/`.

Two stacks demonstrate the two delivery modes:

- **billing** — classic client-side delivery. Matsuri owns every
  field: replicas are declared, the image tracks the converge
  positional.
- **checkout** — server-side delivery. The deployment applies by field
  ownership; matsuri omits the image, replicas, and resources, seeds
  them at creation, and cedes them to the operators that will own them
  (deployment operator, HPA, in-place autoscaler).

## Prerequisites

The minikube test cluster must be running under the `matsuri` profile:

```bash
# from the matsuri repo root
tests/bin/minikube-start.sh
```

The script also applies `platform/namespaces/` — raw manifests, outside
matsuri, because namespaces precede anything matsuri converges.

**macOS gotcha:** kubectl and minikube dial the VM over the local
network, which macOS gates behind a Local Network permission. Run from
a terminal that has the grant (System Settings → Privacy & Security →
Local Network). tmux counts as its own responsible process and cannot
be granted from the CLI — `no route to host` from inside tmux while the
cluster is fine is this, not the cluster.

Then, from this directory:

```bash
bundle install
```

## Creating the Stacks

The first converge creates everything a stack needs:

```bash
bin/matsuri local_billing_dev converge billing
bin/matsuri local_checkout_dev converge checkout
```

Each stack has its own local environment, pointed at the minikube
cluster with its own namespace (`billing-dev`, `checkout-dev`); see
`config/platform.rb`. Checkout's first converge routes through the
seeding protocol: a seeded create completes the boot payload, the
declared server-side apply takes ownership of matsuri's fields, and the
seed owner cedes the rest.

## Applying Changes

Edit a definition, preview, then converge the stack:

```bash
bin/matsuri local_billing_dev diff stack billing     # what would change
bin/matsuri local_billing_dev converge billing       # apply it
```

`show stack <name>` renders the full manifests without touching the
cluster.

For **billing**, a new image rides the converge positional:

```bash
bin/matsuri local_billing_dev converge billing v1.2.3
```

For **checkout**, matsuri never carries the image: converge reapplies
only the declared fields, and the seeded trio stays with whatever
manager owns it. To play the deployment operator locally:

```bash
kubectl --context matsuri -n checkout-dev \
  set image deployment/checkout-web checkout=registry.acme.io/checkout:v2
bin/matsuri local_checkout_dev converge checkout   # does not claw it back
```

The staging environments (`billing_staging`, `checkout_staging`) are
illustrative — they name a cluster that does not exist — and add the
node-selection vocabulary the local environments leave out (see the
`case Matsuri.environment` in `platform/pods/`).
