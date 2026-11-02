# Server-Side Apply Design

This describes the constraints and properties of matsuri's server-side
delivery design: how one repo's declaration coexists with other writers
on the same Kubernetes objects. This is intended to provide both a
grammar for using server-side delivery and for extending it.

The promises mentioned in this document are understood as concepts from
Promise Theory.

## Framing

Under server-side apply, the apiserver merges by field ownership: an
object is a meeting place of managers, each owning the fields it last
sent. The merge is a fold across parties, but not a defined fold — the
managers are unordered, and there is no uniform identity element, so the
structure is not fully monoidal. Each party can promise only its own
fields.

Matsuri's position in that ensemble is fixed: own exactly what the
definition declares, cede everything else. Every constraint below exists
to hold that position. The seeding protocol exists because creation is
the one moment the position cannot be held by a single apply.

## Constraint: ownership follows declaration, and nothing is read back

The ongoing payload contains exactly the fields the repo manages.
Matsuri never reads live cluster state to decide a declaration: a field
another party rolls — an image a deployment operator delivers, a count
an autoscaler moves — is omitted from the payload, not read back and
re-sent.

Properties:

- The declaration is the ownership record. What the repo owns on the
  cluster is what its definitions say, reviewable in the same diff that
  reviews any other change; there is no second registry of claims.
- Other writers take their fields uncontested. A controller that scales
  or a deliverer that rolls an image is never fought, because the repo
  never speaks about those fields at all — there is no flapping between
  two sources of truth.
- A conflict is information. Because the payload never carries a field
  by accident of read-back, a conflict always marks a field two parties
  genuinely both claim — never noise from a value that merely drifted.

## Constraint: empty is the identity element, and the identity is never serialized

An empty value in a payload is an ownership claim over nothing — and the
server does not persist it. Persistence normalizes empties away, and
inside an atomic struct the normalized persisted value and a serialized
empty diverge; under field ownership that divergence is a conflict, not
a merge. So payloads declare in persistence normal form: nil and empty
collections are pruned at the delivery boundary, and ceding a field and
saying nothing are structurally the same act.

Because the merge is not fully monoidal, the pruning carries an explicit
exception list: for some fields an empty value is a genuine assertion —
a field held empty against other writers — and those are declared by
path.

Properties:

- The create's echo equals the declaration. What the server persists
  from the seeded create is value-equal to what the ongoing apply sends,
  so the equal-values co-ownership the seeding protocol depends on holds —
  including inside atomic structs, where any divergence is loud.
- Generation stays unconditional. A definition may render its empty
  collections unconditionally, the natural shape for a generator; the
  delivery boundary, not the generator, knows persistence normal form.
- Emptiness never claims a field. A rendered-but-empty collection cannot
  quietly make the repo co-owner of something it does not manage.
- An empty value that reaches the cluster is deliberate. It survives
  only by appearing in the exception list, so it is named, reviewable,
  and distinguishable from an accident of rendering.

## Constraint: creation is a protocol, not a verb

A seeded field — the boot image, an initial replica count — must exist
from the seeded create and end owned by no one, because the ongoing
declaration never carries it. No single apply can promise both. Creation therefore runs as
three acts: create the seeded payload under the seed owner (a manager
named for the ongoing one, with a seed suffix), deliver the declared
payload with an ordinary server-side apply, then cede — remove the seed
owner's managedFields entry with an atomic test-and-remove. The order is
not stylistic: an apply against an object with empty managedFields
attributes every pre-existing field to a synthetic manager that never
applies again and so never relinquishes.

Properties:

- Seeds end unowned. The first writer to touch one — a controller
  scaling, a deliverer rolling the image — takes it without conflict,
  which is the entire point of seeding.
- The ongoing manager ends sole owner of exactly the declared fields,
  and every later delivery is an ordinary apply. The protocol is paid
  once, at seeding.
- An interrupted protocol stays attributable. The seed owner's name is
  derived from the field manager, so a converge that dies mid-protocol
  strands an object whose managedFields still read as this repo's —
  failure does not orphan the claim.
- Re-creation is loud. Creating over an existing object fails rather
  than silently re-seeding fields that other writers may have moved.

## Constraint: a conflict stops delivery, and forcing is a human judgment

Delivery never forces through a conflict. A conflict marks the frontier
where another manager owns a field this declaration sends; crossing it
transfers ownership and overwrites another party's promise. That is an
incident-time judgment, made by a person with the context in front of
them — never a delivery default. The escape hatch is raw kubectl, not a
flag.

Properties:

- Delivery cannot silently take fields. The ownership frontier moves
  only by an explicit human act, so every transfer has an author.
- The preview shares the frontier. Diff for a server-side resource
  dry-runs under the same field manager delivery uses, so the conflict
  diff surfaces is the conflict apply will hit — not a different one
  under a different name.
- Resolution leaves a record. Either the definition stops declaring the
  field — a reviewed cede — or an operator takes it deliberately, once,
  outside matsuri. Both are visible acts; neither is a quiet override.

## Constraint: delivery mode and payload content are orthogonal axes

How a payload travels is the resource's delivery policy; what the
payload says is its presenter pipeline, assembled by intent regime —
bringing into existence, or delivering declared state. Server-side apply
is a value of the first axis only. Moving a resource between client-side
and server-side delivery never changes which presenters run.

Properties:

- Migration is a policy change, not a re-derivation. A resource moves
  between delivery modes as a one-line change, with its pipeline — and
  the review that ratified it — intact.
- One stack can carry both modes. Members migrate individually, so
  adopting server-side delivery is incremental, not a flag day.
- The regimes stay about intent. Creation seeds and normal form attach
  to what the payload means, so they hold identically under either
  transport.
