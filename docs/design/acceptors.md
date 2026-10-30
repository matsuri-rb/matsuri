# Acceptors Design

This describes the constraints and properties of the acceptor design.
This is intended to provide both a grammar on how acceptors can be used,
but also extended.

## Framing

An acceptor maps the information from a different bounded context into
the bounded context of Matsuri -- K8S resources and Matsuri abstractions
such as `stacks`.

This unidirectional mapping deconstructs potentially complex, nested
data into a flat let() space. The acceptor provides a stable keyspace
which can be used within Matsuri resources. Acceptors are not intended
to keep the domain closed, and are typically used to coordinate across
promise layers. Coordination here are promises (intentions) crossing
between contexts: a declared read is one such crossing, demanded by the
consumer that declares it, arriving in the receiver's own terms.

## Grammar

The whole grammar is two promises. An acceptor is instantiated with the
admitted value, whole. It answers exactly the reads it declares, each
one a named definition on a flat surface. Everything else in this
document is a constraint on those two promises and the properties the
constraint induces.

## Constraint: the accepted surface is declared, never inferred

Every read on the surface is an explicit declaration. There is no
delegation, no method_missing, no fallback to the underlying value.

Properties:

- Failure at the boundary is loud and immediate. A read the surface does
  not answer raises at the point of use, instead of a nil surfacing
  later inside a rendered manifest.
- Consumers couple to an owned interface, never to the artifact's
  schema. When upstream renames a field, the remap happens in the
  acceptor, in one place, and no consumer moves.
- Consumption is auditable. The full set of reads a platform permits
  against an artifact is the acceptor's declarations — one file, not a
  search across every consumer.
- Moving a consumer is legible. Whether a different surface can host it
  reduces to one question — does that surface answer these reads — and a
  wrong answer fails loudly, at the cut.

## Constraint: the value is taken whole and deconstructed once

An acceptor receives the entire value at instantiation. There is one
parse site; consumers receive the acceptor instance, never fragments of
the raw value.

Properties:

- Consumers cannot disagree. Every read in an instance derives from the
  same binding, so consistency is structural rather than disciplined.
- The boundary has an address. Questions about what the artifact means
  to this platform have exactly one place to be answered, and changes to
  that meaning have exactly one place to happen.

## Constraint: unconsumed vocabulary passes in silence

An acceptor reads the fields it declares and is silent about the rest.
The silence is directional and deliberate: silent toward the side that
owns the vocabulary, loud toward the side that owns the surface.

Properties:

- Upstream can grow without coordination. New fields in the artifact are
  a non-event for every acceptor that does not read them; no release of
  the platform is needed for the artifact to say more.
- One artifact serves many consumers. A field this acceptor passes over
  may be another consumer's declared read — the artifact carries many
  parties' coordination at once, each acceptor selecting its own. A
  partial consumer that rejected unknown fields would claim the whole
  vocabulary and break the sharing; enforcement of the full vocabulary
  belongs to whatever system owns it, at its own boundary.

## Constraint: every declared read carries its default

Defaults live on the surface, in the declaration of each read — never
scattered through consumers.

Properties:

- The empty value is valid. An acceptor over an empty artifact answers
  every read with its default; emptiness is the identity, not an error
  case.
- Sparse values are the normal case. An artifact overrides only what it
  names and inherits everything else, so the cost of an instance config
  scales with its difference from the defaults, not with the size of the
  surface.
- Shared-tier referents are expressions, not machinery. "This reference
  defaults to the standing instance" is written as the default of one
  read, visible at the declaration, overridable by the artifact.

## Constraint: flat scalars are the golden path, documented rather than enforced

The surface is intended to be granular scalar reads. Declarations that
return nested structures are not prevented.

Properties:

- On the flat surface, override composition stays monoidically lawful:
  defaults are the identity, a sparse artifact is an overlay, and no
  merge semantics are ever needed.
- What a nested return forfeits is named rather than policed: the
  sparse-overlay property stops at that read, and deep-merging the
  structure is where the loss compounds. The cost falls on the
  definition that chose the structure, not on the rest of the surface.

## Constraint: an acceptor does not know its boundary; the accepting site binds it

An acceptor does not know which boundary it stands at. The declaration
that accepts — a stack naming its config acceptor, or any future
accepting site — binds the acceptor at its boundary, under a named
collection; the class itself promises only the grammar above.

Properties:

- One noun serves every foreign admission. New accepting sites bind
  existing machinery; they do not mint new types.
- Acceptors are testable in isolation: hand one a value, read the
  surface. No stack, environment, or cluster is implied.
- The registry definition and a bare class are interchangeable, because
  the contract is only the two promises of the grammar. The registry is
  a convenience of definition, not part of the contract.

## Constraint: acceptors stand only at foreign boundaries

An acceptor is warranted where the admitted value's vocabulary has an
independent owner and lifecycle. Values the platform passes to itself
are already deconstructed by their consumers' own definitions.

Properties:

- The pattern cannot sprawl into a general indirection layer. Where no
  independent owner exists there is no churn to absorb and no remap to
  localize — an acceptor there adds a layer and no property, and the
  definition excludes it rather than a style rule.
- The discriminator is decidable. Whether a boundary deserves an
  acceptor reduces to one question: who owns this vocabulary, and does
  it change on a lifecycle that is not ours?

## Vocabulary note

The noun names the receiving side's act, and the declaration site is its
only habitat: consumers read the accepted value under the collection's
own name, so "acceptor" appears exactly where the policy is declared and
nowhere downstream. The inbound posture — read only what you declare —
has an outbound mirror in manifest transforms, which write only what
they own; the two share a discipline of least contact at boundaries,
never machinery. Resemblance to presenters, adapters, or anti-corruption
layers in other ecosystems may be adjacent and carries none of their
promises.
