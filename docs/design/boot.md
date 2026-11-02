# Boot Design

This describes the constraints and properties of the boot design: the
sequence that takes a process from an invoked binary to a command
running against an environment, with the repo's vocabulary loaded. This
is intended to provide both a grammar for how a Matsuri repo boots, and
for how the boot can be extended.

The promises mentioned in this document are understood as concepts from
Promise Theory.

## Framing

Boot is where several parties meet: the matsuri gem, the platform repo,
the shell that invoked the binary, and the operator or agent that typed
the command. Each party can make promises only about what it owns. The
design assigns each resolution question of boot to exactly one owner, as
layers: each layer makes one promise to the layers above it and assumes
only the layers below.

## Promises

Boot resolves five questions, in order, each with one owner:

1.  Which matsuri runs — promised by the repo's Gemfile.
2.  Where the repo is — discovered from the working directory.
3.  What code the repo contributes — loaded by matsuri from the repo's
    `lib/`.
4.  Which environment is meant — named by the first positional argument.
5.  What is activated — declared by the repo's initializer.

Then the command dispatches. Everything below is a constraint on these
ownerships and the properties each induces.

## Constraint: version binding belongs to the repo's Gemfile

The platform repo locks its matsuri version, and the versions of any
plugins, in its own Gemfile. Matsuri never resolves its own version, and
nothing in boot selects among installed versions. A repo that wants the
binding to be unavoidable ships a `bin/matsuri` wrapper whose whole job
is to pin `BUNDLE_GEMFILE` and exec `bundle exec matsuri`.

Properties:

- The matsuri a repo runs against is a recorded, reviewable promise.
  Upgrades are a diff to the lockfile, per repo, on that repo's cadence.
- Two repos on one machine can promise different matsuri versions
  without negotiation.
- The wrapper has no logic to drift. Pin and exec is the entire content;
  everything else the old wrappers did is owned by a layer below.

## Constraint: discovery anchors at the working directory

Matsuri finds the repo by walking up from the working directory looking
for `config/matsuri.rb`. The contract of use is to invoke from the repo
base — where the Gemfile is, in the manner of terraform or chef — and
the walk-up exists as forgiveness for subdirectory invocation, not as a
second contract. No environment variable, registry, or wrapper location
tells matsuri where repos live; standing in the repo is the claim.

Properties:

- Repo identity and version binding coincide. Invoked at the repo base,
  the repo that discovery finds is the repo whose Gemfile bound the gem;
  there is no configuration by which they diverge.
- The invocation is portable. A command that works in one checkout works
  in another path, another machine, another agent's worktree — nothing
  about boot is anchored to an absolute location.
- Failure is immediate and names its cause: no `config/matsuri.rb` on
  the walk up means no repo, before any command logic runs.

## Constraint: the repo contributes code through matsuri, not through its launcher

Immediately after discovery, matsuri prepends the repo's `lib/` to the
load path. The repo does not acquire a gemspec to get load-pathing from
bundler, and the wrapper does not export load paths. A platform repo is
an application; matsuri is what makes it loadable.

Properties:

- Requiring the repo's own library behaves identically under
  `bundle exec`, a bare gem install, and a checkout. The repo's
  extension pattern makes no assumption about who launched the process.
- The repo never misdeclares itself as a gem. No version, no files list,
  no packaging promises made solely to obtain a load path.
- Every repo-authored file in the boot chain — configuration, platform
  definitions, the initializer — may assume `lib/` is loadable, because
  the load path precedes all of them.

## Constraint: the environment has exactly one source

The environment is the first positional argument:
`matsuri <env> <verb> ...`. There is no ambient override and no
detection from the binary's name. A repo that wants per-environment
entry points writes them as argument injection — `bin/staging` is
`exec bin/matsuri staging "$@"` — which keeps the sugar in the repo and
out of the grammar.

Properties:

- The command is self-describing. What was typed, what `ps` shows, what
  the CI log recorded, and what matsuri resolved are the same string;
  during an incident there is no exported variable to go find.
- One invocation grammar. Every surface that composes a matsuri command
  — documentation, pipelines, agents, muscle memory — constructs the
  same shape, and the environment slot cannot be consumed twice.
- Renaming or symlinking the binary is a non-event. No name is
  significant, so no name is a trap.

## Constraint: declaration and activation are separate promises

The Gemfile declares what exists; the initializer activates what this
repo uses. Configuration (`config/matsuri.rb`, `config/platform.rb`) is
declarative — defaults and environment definitions, no requires. The
initializer (`config/initializer.rb`) is the one site that requires
plugins and the repo's own library, and it runs after configuration is
loaded, before any command logic.

Properties:

- A declared-but-unactivated plugin costs nothing and breaks nothing.
  Adding a gem to the Gemfile is not yet a decision about boot.
- Activation order is repo-owned and readable in one file. What this
  platform loads, and in what order, is the initializer — not a search
  across configuration.
- Plugins activate against resolved configuration. By running after the
  configuration layer, an initializer may branch on environment or
  settings without ordering hazards.
- The boot sequence is a fixed spine — bound, discovered, loadable,
  named, configured, activated, dispatched — and extension happens at
  the one joint designed for it.
