# Stacks Design

This describes the constraints and properties of the stack design. This
is intended to provide both a grammar on how stacks can be used, but
also extended.

## Framing

A stack is the span of a single management promise: a bundle of
Kubernetes resources that one operator converges as one act. The noun
answers "what do we manage together?" — it deliberately does not answer
"what talks to what?" or "what constitutes the whole system?". Each
constraint below keeps that promise narrow; the properties follow from
the narrowness.

## Constraint: membership is decided by co-management only

A resource belongs to a stack because its operator wants to converge it
together with the others — one owner, one lifecycle, one converge act.
Runtime topology, architectural wholeness, and system boundaries are
not membership criteria.

Properties:

- The management partition is orthogonal to the runtime connector
  graph. Two workloads may communicate heavily and live in different
  stacks; two may never speak and share one. Runtime coupling does not
  force co-membership, and co-membership promises nothing about
  reachability.
- One noun serves every scale. A stack may be an entire platform or a
  single service with its sidecars; because the noun claims only
  co-management, it does not lie at either extreme, and there is no
  ladder of bigger nouns to invent.
- Membership is revisable. Moving a workload between stacks reassigns a
  management promise, nothing more. The cost is confined to the cut:
  an in-stack neighbor is reached by local name, an out-of-stack
  neighbor by an address carried in configuration. The change is small,
  explicit, and visible in the definitions.
- Wholeness is not required, but filled references are. A stack need
  not contain everything it depends on; every dependency it does not
  contain must resolve to an address.

## Constraint: instance data arrives as an argument, not as ambient state

A stack-config binds at the stack definition, as an argument to the
converge act. It is never folded into the global configuration, which
remains the environment's ambient state.

Properties:

- Many instances of one stack can exist in one environment. Ambient
  state is process-global and would quietly promise a single instance;
  an argument makes the instance count a non-event.
- No collision surface. Stack-config keys never enter the framework's
  configuration keyspace, so no key can shadow or be shadowed by
  framework configuration, and no merge semantics are ever needed.
- Provenance survives. The configuration that was passed and the
  manifests that were rendered remain separately readable; nothing is
  destroyed by merging.

## Constraint: one stack-config per instance, taken whole

The stack-config is a single value. The stack deconstructs it through
its own definitions; members never receive private variants.

Properties:

- Members cannot disagree. Every resource in the instance derives from
  the same binding, so consistency across the instance is structural
  rather than disciplined.
- Deconstruction is legible. Which fields a stack consumes is read
  directly from its definitions, not from a merge trace.

## Constraint: instance identity is the (stack, stack-config) pair

A stack name alone names a definition. An instance is the definition
bound to a stack-config, and every operation on an instance addresses
the pair.

Properties:

- Instances of the same stack coexist without qualification schemes —
  the identity that distinguishes them is already in the address.
- No operation is ambiguous in an environment holding many instances;
  status, converge, and delete all name the same pair.

## Constraint: parse the grammar, never own the vocabulary

Matsuri validates that a stack-config is well-formed. It makes no claim
to know every key: definitions lift the fields they consume and are
silent about the rest.

Properties:

- The stack-config can be shared. One document may serve several
  consumers (deployment tooling, controllers, humans); a partial
  consumer that rejected unknown keys would claim the whole vocabulary
  and break the sharing.
- The promise is honest. Which keys are consumed is decided by the
  definitions that read them, which is not enumerable in advance;
  failing loudly on "unknown" keys would promise an authority matsuri
  cannot have. Strict vocabulary enforcement belongs to whatever system
  owns the vocabulary, at its own boundary.
- Vocabulary can grow without gem changes. The gem ships the mechanism
  — the flag, the loading, the binding; what any key means is defined
  entirely by the repository's own definitions.

## Constraint: environment and stack-config vary on different axes

An environment is a committed, closed set naming a tier — where things
run and under what posture. A stack-config is an open set naming an
instance — what this particular deployment of a stack is. Neither
substitutes for the other.

Properties:

- Dynamic environments without environment proliferation. The
  lifecycle-driven case (a short-lived instance per feature branch)
  is carried by instance data; the tier set stays small, static, and
  reviewable.
- Tier concerns stay in code review; instance concerns stay in data.
  Changing a cluster mapping is a change to committed definitions;
  spinning up another instance is a new stack-config file.

## Constraint: cross-stack connections are references with defaults; a pin is the only override

Where a stack depends on something outside itself, the dependency is a
reference. References resolve to a default — the standing instances of
a shared tier such as staging — and a stack-config may pin any
reference to a different address. Pinning is the only override form.

Properties:

- An instance is a sparse override. Instantiating a stack for a feature
  costs the stack itself plus the pins that differ; everything not
  mentioned follows the defaults. Cost scales with the diff, not with
  the size of the platform.
- Composition is by reference, never co-location. Two stacks owned by
  different operators compose by one pointing at the other's address —
  two configs, two lifecycles, one field between them.
- Coordination is recorded, not minted. When two owners agree to wire
  their instances together, the pin records the outcome of an agreement
  made between people; the mechanism imposes no registry, broker, or
  naming authority of its own.

## Vocabulary note

Names make implied promises, and the flag grammar is part of the name.
A plural noun with a source suffix (`--values-from=`) promises a
document folded into a keyspace — overlay and merge semantics. The
singular `--stack-config=` promises an argument the render is for.
Stack-config is defined only in matsuri's own terms, as stated above;
resemblance to concepts in other tools is incidental and carries none
of their contracts.
