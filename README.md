# Matsuri

Matsuri manages Kubernetes manifests. Matsuri uses the full Ruby
language for generating manifests. Unlike Helm, it constructs these with
Ruby objects instead of using string-based templating.

Resources are defined by `let()` extracted from `rspec`. These values
can be applied monoidally in a flat keyspace, through mixins
(`Concerns`) or Ruby inheritance. It ultimately constructs a hash data
structure which the harness feeds into `kubectl` to apply to a target
cluster.

Since Matsuri *generates* manifests from hash objects, values can be
safely inserted. Fragments are just more hash objects. Helper methods
can be written. [Acceptors](docs/acceptors.md) can be defined to import
configuration values and resource definitions can inject them in.

Similar to Kustomize's design, Matsuri also includes a full transform
algebra, both for importing upstream manifests, as well as applying
transforms after generation. [Presenters](docs/presenters.md) can be
used to create seed values on creation. Subsequent applications through
Server Side Apply can omit seed presenters, allowing Matsuri to cede
those values for other operators to manage.

The final hashes are encoded as JSON or YAML, and not before. This
allows Matsuri to inject, manipulate, and transform manifests as
structured data, instead of as strings.

Finally, Matsuri provides a [Stack](docs/stacks.md) abstraction. These
bundle together a collection of resources that can be applied together.
When combined with acceptors, this allows for automatically standing up
preview environments.

## History

Matsuri was originally created to help stand up a local K8S cluster for
a dev environment, while also managing deployments to a staging and
production environment. Better tools, such as `k9s` and `minikube`, have
since been developed by the Kubernetes community.

While Helm has emerged as the de facto industry standard, and kustomize
closes many of Helm's design flaws, Matsuri can do something neither do
well: it can dynamically generate whole stacks.

Unlike cdk8s, Matsuri's use of monoidal merges allows for a far greater
degree of composability and extensibility. Its tradeoff is the use of
Ruby, which not all platform engineering teams may have expertise in.

In an era of AI coding assistance, platform teams can leverage coding
agents to assist with using Matsuri. The current release includes the
design grammar, rspec demonstrating golden path patterns, and usage
documentation to help get things started. Consider using Matsuri if you
need to dynamically set up Kubernetes resources.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'matsuri'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install matsuri

## Usage

The documentation covers the golden paths:

- [Setup](docs/setup.md) — environments, kubectl contexts, and
  namespaces
- [Resources](docs/resources.md) — defining resources with `let()`
- [Stacks](docs/stacks.md) — bundling resources and converging them
  together
- [Acceptors](docs/acceptors.md) — importing configuration values
- [Presenters](docs/presenters.md) — transforms, seeds, and server-side
  apply
- [Diff](docs/diff.md) — previewing what converge will send
- [Local Development](docs/local-dev.md) — the local-dev workflows
- [Known Issues](docs/known-issues.md)

Design notes — the constraints and the properties they induce — live in
[docs/design](docs/design).

## Development

There is a Nix flake containing the dependencies for developing Matsuri.
This includes Ruby and minikube. A `.envrc` is set up for `direnv`
users. The gems are not a part of the flake so you will still have to
run

    bundle install

Coding agents can invoke commands with

    direnv exec . bundle exec rake

To release a new version, update the version number in `version.rb`, and
then run `bundle exec rake release`, which will create a git tag for the
version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## License

Matsuri is distributed under the MIT License

## Contributing

Bug reports and pull requests are welcome on GitHub at
<https://github.com/matsuri-rb/matsuri>.
