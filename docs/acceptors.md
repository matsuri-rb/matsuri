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
  # identity
  let(:instance_name) { options[:name] }
  let(:namespace)     { options[:namespace] }

  # declared settings, with the defaults this surface promises
  let(:log_level)    { options[:log_level] || 'info' }
  let(:worker_queue) { options[:worker_queue] || 'default' }

  # a reference: the default points at the shared tier, an entry in the
  # artifact overrides it
  let(:search_api_url) do
    options.get(:pins, 'search-api') || 'https://search.staging.svc.cluster.local'
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

## Seams and Built-in Acceptors

A stack binds acceptors at named seams, declared with `accept`. Last
declaration per seam wins. `Matsuri::Stack` ships one implicit seam:

```ruby
accept :image_tag, Matsuri::Acceptors::ImageTag
```

The built-in acceptor declares a single read, `image_tag`, defaulting to
`latest` — the only place that default lives. The converge positional
(`matsuri converge app v42`) arrives through this seam; with no
positional, the seam admits the empty value and the default answers.

A stack overrides the seam by re-declaring it with its own acceptor
(registry name or class):

```ruby
Matsuri.define :stack, 'app' do
  accept :image_tag, 'pinned-image-tag'

  needs :deployment, 'app-web'
end
```

Downstream resources do not have to listen. Members that never read
`image_tag` are unaffected by what the seam admits, and the workload
classes themselves carry no default — a definition instantiated below
any seam that wants one declares its own.

## Acceptors and Stacks

Stacks are the first consumer. A stack takes a stack-config artifact for
the instance being converged, hands it to the stack's acceptor once, and
members read the acceptor instance as `stack_config` — one binding per
instance, so members cannot disagree about what was accepted. The stack
wiring is described in [stacks](stacks.md).

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
