# Acceptors

An acceptor maps the information from a different bounded context into
the bounded context of Matsuri -- K8S resources and Matsuri abstractions
such as `stacks`.

The promises:

- Fields the acceptor does not declare are ignored. Upstream can add
  vocabulary freely without breaking anything downstream.
- Reads the acceptor does not declare raise `NoMethodError`. Nothing
  reaches past the declared surface.
- There is no fallback to the underlying value. When upstream renames a
  field, the remap happens in the acceptor, in one place, and consumers
  do not move.

## Defining Acceptors

Acceptors are defined in `platform/acceptors`. The raw value arrives
whole as `options`; each `let` declares one read on the accepted
surface.

```ruby
Matsuri.define :acceptor, 'app' do
  # the artifact anchor owns the empty value
  let(:artifact) { options || {} }

  # identity
  let(:instance_name) { artifact[:name] }
  let(:namespace)     { artifact[:namespace] }

  # declared settings, with the defaults this surface promises
  let(:log_level)    { artifact[:log_level] || 'info' }
  let(:worker_queue) { artifact[:worker_queue] || 'default' }

  # a reference: the default points at the shared tier, an entry in the
  # artifact overrides it
  let(:search_api_url) do
    (artifact[:pins] || {})['search-api'] || 'https://search.staging.svc.cluster.local'
  end
end
```

Keep the declared surface to flat scalar values. Lets that return nested
structures will work, but you give up treating an instance config as a
sparse overlay of the defaults — and deep-merging nested returns is
where that goes wrong.

Because every declared read carries its default, an empty value is a
valid one: every read lands on its default. A sparse artifact overrides
only what it names.

The empty value belongs to the acceptor, because what empty means is
specific to the vocabulary it admits: every declared read is total over
nil. A hash-shaped surface anchors once —
`let(:artifact) { options || {} }` — and reads fields off the anchor; a
scalar surface reads `options` whole, as the built-in image tag acceptor
does.

## Reading

An acceptor is instantiated with the raw value and read through its
declared surface:

```ruby
acceptor = Matsuri::Registry.acceptor('app').new(config)

acceptor.namespace       # declared       => the artifact's value
acceptor.log_level       # not in config  => 'info'
acceptor.owner           # not declared   => NoMethodError
```

Note on defaults: the artifact usually arrives as a `Map`, and
`Map#fetch` does not honor Hash's default-value argument (it requires a
block). Use `options[:key] || default`.

## Bare Classes

The registry definition is the golden path, not a requirement. Any class
that is instantiated with the raw value and answers the declared reads
is an acceptor:

```ruby
class AppConfig
  include Let
  include RLet::LazyOptions

  let(:namespace) { options[:namespace] }
end
```

## Built-in Acceptors

A stack registers acceptors under named collections with `accept`; last
declaration per collection wins. The collection name is the options key:
each acceptor admits its own component of the invocation options, whole,
and cannot see another collection's component. Whoever constructs the
stack supplies data under those keys.

`Matsuri::Stack` ships two built-ins:

```ruby
accept :image_tag, Matsuri::Acceptors::ImageTag
accept :config,    Matsuri::Acceptor
```

The `:image_tag` collection carries a scalar. The converge positional
(`matsuri converge app v42`) arrives whole, and the acceptor's single
read, `image_tag`, owns the `latest` default — the only place that
default lives. With no positional, the acceptor admits the empty value
and the default answers.

The `:config` collection carries the stack-config artifact. Its built-in
is the empty acceptor: the collection is total — `stack_config` is the
same kind of value on every stack — and its surface is empty until a
platform re-declares the collection with its own acceptor.

A stack overrides a built-in by re-declaring its collection with its own
acceptor (registry name or class):

```ruby
Matsuri.define :stack, 'app' do
  accept :image_tag, 'pinned-image-tag'
  accept :config,    'app'

  needs :deployment, 'app-web'
end
```

Downstream resources do not have to listen. Members that never read
`image_tag` are unaffected by what the acceptor admits, and the workload
classes themselves carry no default — a definition instantiated outside
a stack that wants one declares its own.

## Acceptors and Stacks

Stacks are the first consumer. The stack never loads anything: the CLI
owns the boundary mapping between the user invocation and the stack's
promise, loading the file named by `--stack-config=` and supplying the
data under the `:config` key. Anything else that constructs a stack — a
spec, a controller, other tooling — supplies data the same way, with no
file involved. The stack binds its acceptor once per instance, and
resource members read the acceptor instance as `stack_config` — one
binding per converge, so members cannot disagree about what was
accepted. A missing flag is the empty value: every declared read lands
on its default. A flag with a bad path fails loudly; there is no
fallback. The stack wiring is described in [stacks](stacks.md).

## One Artifact, Many Consumers

An artifact usually carries vocabulary for more than one consumer, and
an acceptor claims only its own reads. Consider a feature-environment
artifact — an engineer names the environment, and the provisioning side
derives the rest:

```yaml
name: feat-checkout
namespace: feat-checkout
dns_name: feat-checkout.example.dev
expires_at: "2026-11-15"
contact: team-checkout
```

The stack's acceptor declares the fields the stack coordinates on — the
namespace, and the dns name it needs to configure CORS:

```ruby
Matsuri.define :acceptor, 'app' do
  let(:namespace) { options[:namespace] }
  let(:dns_name)  { options[:dns_name] }
end
```

`expires_at` and `contact` pass through this acceptor in silence. They
are not dead vocabulary — they are the coordination path between an
environment reaper and whoever provisions environments. The reaper does
not have to be a matsuri consumer at all; it reads the same artifact on
its own terms. Adding those fields required no change to this acceptor,
and the stack never sees them.
