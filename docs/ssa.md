# Server-Side Apply

Server-side delivery hands the merge to the apiserver: instead of the
client's three-way last-applied merge, the server tracks which manager
owns which field and merges by ownership. Choose it when an object's
fields are genuinely shared — a deployment operator rolls the image, an
HPA moves the count, an in-place autoscaler adjusts sizing — and the
repo should own only what it declares.

The posture: matsuri owns exactly the fields the definition declares and
cedes everything else. The declaration is the ownership record; matsuri
never reads live state to decide what to send. The constraints behind
this are in [docs/design/ssa.md](design/ssa.md).

## Enabling It

Server-side apply is one value of the `apply_via` delivery axis, per
resource:

```ruby
Matsuri.define :deployment, 'app-web' do
  let(:apply_via) { :server_side_apply }
  # ...
end
```

Applies are delivered under the repo's field manager —
`Matsuri::Platform.field_manager`, default `matsuri` — overridable per
resource with `let(:field_manager)`. Delivery mode and presenter
pipeline are orthogonal: flipping a resource's `apply_via` never changes
which presenters run, so members of a stack can migrate individually.

## Declare Only What You Manage

The ongoing payload should carry exactly the fields the repo owns.
Fields another writer rolls are omitted, not read back: a deployment
whose image is delivered by an operator declares its containers by name
without an image, and one whose count an HPA moves declares
`let(:replicas) { nil }` (Deployment's spec compacts, so nil is clean
omission). Boot values for those fields ride `:on_create` seeds — see
[Seeds](presenters.md#seeds) — so the seeded create lands the object
whole and the seeds end owned by no one.

## Persistence Normal Form

The server does not persist empty values — it drops them on storage —
and inside an atomic struct like `.spec.selector`, a payload carrying an
empty member no longer equals the persisted value, which turns the
creation hand-off into a conflict. An empty collection is also an
ownership claim over a field the definition does not manage.

So a server-side resource's payloads declare in persistence normal form:
declare `prune_empty` on both intent regimes, after any seeds, on the
stack (or the resource):

```ruby
Matsuri.define :stack, 'app' do
  needs :deployment, 'app-web'
  needs :service,    'app-web'

  present :on_create, match_deployments(seed_replicas(2))
  present :on_create, match_deployments(seed_image('registry.example.com/app:boot'))

  present :on_create, prune_empty
  present :on_apply,  prune_empty
end
```

A field that must be held empty against other writers is a genuine
assertion, not an accident of rendering — carry it in the exception list
(`prune_empty(except: [...])`). The mechanics and the exception grammar
are in [Prune Empty](presenters.md#prune-empty).

## The First Converge

Creation under server-side delivery is a protocol, not a single verb,
and the delivery verbs run it for you: `apply` (and so converge) routes
a resource that is not yet live through it, `create` brings one into
existence through it, and `recreate` tears down and reseeds. Three
steps:

1.  Create the seeded payload as `<field_manager>-seed`.
2.  Deliver the declared payload with an ordinary server-side apply.
    Equal values co-own, which is why normal form matters at this step.
3.  Cede: atomically remove the seed owner's managedFields entry. The
    declared fields end solely owned by the field manager; the seeds end
    unowned, free for the first writer that wants them.

A first converge looks like:

```console
$ bin/matsuri staging converge app
deployment.apps/app-web created
deployment.apps/app-web serverside-applied
service/app-web created
```

Every later apply is an ordinary server-side apply. `save_config` is
pinned false under this mode — a seeded last-applied is a prune trap for
any later client-side apply — so there is nothing to configure.

The protocol and its refuted alternatives are pinned by
`tests/bin/probe-ssa.sh`.

## Conflicts

A conflict means another manager owns a field this declaration sends:

    error: Apply failed with 1 conflict: conflict with "some-operator"
    using apps/v1: .spec.template.spec.containers[name="app"].image

Matsuri never passes `--force-conflicts`; forcing transfers ownership
and overwrites another party's work, which is a human judgment. Two
resolutions:

- **Cede the field.** If the other manager is its rightful owner, stop
  declaring it: omit it from the definition (and seed it on create if
  the object needs it at creation). This is the common case and lands as
  an ordinary reviewed change.
- **Take the field.** If the repo is the rightful owner, take it once
  with raw kubectl under the repo's manager —
  `kubectl apply --server-side --force-conflicts --field-manager=matsuri -f -`
  — then the next matsuri apply is ordinary.

`diff` for a server-side resource dry-runs under the same field manager
apply uses, so a conflict surfaces in the preview as the same loud error
delivery would hit.

## An Interrupted First Converge

A converge that dies mid-protocol strands an object still owned by
`<field_manager>-seed` — the cede never ran, so the seed owner holds its
fields forever and a retry conflicts with it. Recognize it by reading
ownership:

```console
$ kubectl get deployment app-web --show-managed-fields -o json \
    | jq '[.metadata.managedFields[].manager]'
```

If `matsuri-seed` appears on an object whose converge is not currently
running, the recovery is to delete the object and reconverge — the
seeding protocol runs only at creation, so it must restart from a clean
create:

```console
$ kubectl delete deployment app-web
$ bin/matsuri staging converge app
```
