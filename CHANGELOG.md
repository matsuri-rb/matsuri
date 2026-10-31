# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Working toward 0.3.0.

### Breaking

- **Delivery moves off the resource classes into `Matsuri::Tasks::KubectlOps`.**
  Resources are pure manifest generators; the kubectl mechanism lives in
  one task per verb (`Apply`, `Create`, `Replace`, `Delete`, `Recreate`,
  `Scale`, plus the `Get` read), and the CLI selects the task. The
  module-level boundary functions (`KubectlOps.apply/create/delete/
  recreate/scale/converge`) are the single site deriving task inputs from
  a rendered resource — post-generation manifest transforms will slot in
  there. Consequences:
  - `Kubernetes::Base` loses `create!`, `apply!`, `replace!`, `delete!`,
    `recreate!`, `annotate!`, `converge!`, `converge_by_apply!`, and
    `converge_by_recreate!`. Definitions overriding these must declare
    delivery policy instead: `let(:converge_via)` (`:apply` default,
    `:recreate`), `let(:apply_via)` (`:apply` default, `:replace`), and
    `let(:save_config)` (default `true`). Pod, Secret, and ConfigMap
    express their converge-by-recreate behavior through these lets.
  - `annotate!` is removed outright: nothing bound it since `--record`
    died, and deliberate annotation belongs to the manifest + apply path.
  - `status!` is removed from `Kubernetes::Base`. It was a fatal stub no
    resource ever implemented — every `status <type> <name>` died with
    "I don't know how to display a status". The `Status` task renders
    `kubectl get -o wide` instead, so the verb works for the first time.
    `Stack#status!` remains the overridable hook for stack definitions.
  - `Concerns::Scalable` is removed; `scale` is a task, and the CLI table
    already names which workloads scale.
  - `ImportedManifest` drops its five fatal verb stubs. Apply-only is now
    structural — the CLI never bound the other verbs — and its custom
    `apply!` is the same `Apply` task fed multi-doc YAML.
  - Create/apply payloads are sent as YAML rather than JSON (one payload
    shape serves single- and multi-doc manifests); semantics unchanged.
  - `ExportManifest#applied_to_yaml` is fixed (previously raised
    `NoMethodError`); it is now the canonical apply payload.
  - `Kubernetes::Base#created?` is removed; the existence check is
    `Tasks::KubectlOps.exists?(resource)` (the `Get` read task, which
    `converge` already used). The verbose "already started / not
    started" narration moves to `Get#exists?`. With it goes Base's
    `ShellOut` include — resources no longer shell out at all.

- **`Concerns::ImportManifest` keeps only the import surface.** The
  transform ops move to `Matsuri::Transform` (the concern includes the
  Kubernetes dialect, so call sites inside definitions are unchanged),
  and the set-carrier lookups (`lookup_manifests`, `without_manifest`,
  criteria matching) stay. Two declarations change shape:
  `with_resources` was a let holding a curried lambda
  (`with_resources.(name, spec)`) and is now the dialect method
  (`with_resources(name, spec)` — same returned step, no lambda-call on
  the name); `node_selector_terms_path` was an overridable let and is
  now the dialect constant `NODE_SELECTOR_TERMS_PATH`.

- **The client-side diff moves off the resource classes into
  `Matsuri::Concerns::Diffable` + `Matsuri::Tasks::HashDiff`.** The
  comparison is the resource's (`Diffable#diff(current)` takes the
  manifest compared against and returns filtered deltas; the noise
  filters remain the per-resource override surface); fetching the
  current manifest and printing belong to the `HashDiff` task. This
  diff is a permanent companion to the planned server-side
  `KubectlOps::Diff` (`kubectl diff`), not a stopgap: with admission
  controllers in play, the server-side diff shows what admission
  injects, while this one shows drift relative to the declaration
  with that noise filtered out. Consequences:
  - `Kubernetes::Base` loses `diff!`, `diff` (zero-arg), `print_diff`,
    and `current_manifest`. Library callers of `current_manifest` use
    `Tasks::KubectlOps.manifest(resource)` (a plain parsed hash — the
    `Map` wrapping and `raw:` flag are gone).
  - The per-class `primary_container_diff`/`containers_diff` overrides
    on Pod, ReplicaSet, and Deployment are replaced by a declarative
    `let(:primary_container_path)`; the focused diff projects both
    manifests by that path generically.
  - `--primary-container` works for the first time on `pod` (previously
    `NoMethodError`: `Pod#diff!` called a method that never existed)
    and on `stateful_set`, `daemon_set`, and `cron_job` (previously
    silently fell back to a full diff). All workloads with a pod
    template now declare the path.
  - `unit_comparison_is_equal?` no longer crashes on non-string values
    (`Object#=~` was removed in Ruby 3.2; any diff touching a Hash or
    Array value raised `NoMethodError` on modern Ruby).

- **Bare `diff` is now the server-side diff.** `matsuri <env> diff <type>
  <name>` runs `kubectl diff` (`Tasks::KubectlOps::Diff`): the apiserver
  dry-runs the same payload `apply` would send through defaulting and
  admission, and the output shows live-vs-admitted — admission injections
  included. `--hash-diff` restores the client-side filtered diff
  (`Tasks::HashDiff`), which answers a different question: drift relative
  to the declaration with cluster-owned noise filtered out. Both are
  permanent. `--primary-container` is a HashDiff-only projection and
  implies `--hash-diff`. kubectl's exit-code convention is honored: no
  output and exit 0 means no differences; only exit codes above 1 are
  errors.

- **`Matsuri::App` is renamed `Matsuri::Stack`.** A stack is a bundle of
  resources managed together — one owner, one converge act; "app" never
  described that. Registry type is `stack`, definitions load from
  `platform/stacks`, the definition module is `Stacks`, and the CLI verbs
  address stacks. There is no back-compat alias for the `app` type;
  definitions must rename their directory and `Matsuri.define :app` calls.
- **Workload `image_tag` defaults are removed.** Pod, Deployment,
  ReplicaSet, ReplicationController, StatefulSet, DaemonSet, and CronJob no
  longer default `image_tag` to `latest`; the default lives in the built-in
  `Matsuri::Acceptors::ImageTag` registered under the stack's `:image_tag`
  collection. Definitions instantiated outside a stack (bare `.new`,
  library use) that relied on the implicit `latest` must declare their own:
  `let(:image_tag) { options[:image_tag] || 'latest' }`. Resource-level
  CLI verbs supply the tag explicitly and are unchanged.

- **Ingress emits `networking.k8s.io/v1`** (was `extensions/v1beta1`,
  removed in Kubernetes 1.22). `spec.backend` is now
  `spec.defaultBackend`; the `path` helper emits `pathType` (default
  `Prefix`) and the v1 backend shape
  (`service: { name:, port: { number: | name: } }` — an Integer port is
  a number, anything else names a port); `ingress_class` now renders as
  `spec.ingressClassName` instead of the retired
  `kubernetes.io/ingress.class` annotation. Definitions that hand-rolled
  `rules` or `default_backend` in the v1beta1 shape must move to the v1
  shape.

### Removed

- **`Kubernetes::Base#build!`** — a NotImplementedError stub with no
  caller: no CLI verb binds a per-resource build, and the working build
  path has always been the stack-level hook (`Stack#build!`, supplied by
  the stack definition and driven by `matsuri <env> build <stack>`).
  A definition that implements its own `build!` is unaffected; direct
  callers of the stub now get NoMethodError instead of
  NotImplementedError.
- **`--record` everywhere kubectl is invoked** — create, apply, replace,
  scale, imported-manifest apply, and `Deployment#rollout!`. kubectl
  deprecated the flag (~1.22): it stamped the
  `kubernetes.io/change-cause` annotation as a side effect of imperative
  verbs, recording a command rather than an intent. Nothing replaced it
  server-side — SSA's managedFields attributes who owns a field, not why
  it changed. The intention here is to support
  `kubernetes.io/change-cause` deliberately, as a post-generation
  manifest transform stamping a platform-supplied value (release id,
  ticket, ref) on the declarative path. The diff logic keeps treating
  change-cause as an always-changed path.
- **ReplicationController support.** The resource type, its registry
  entries and `rc` aliases, the `rc` subcommands on
  show/diff/create/delete/recreate/apply/scale/status, the `rcs_path`
  config key, and the `rollout` verb. `rollout` was the client-side
  rolling update — mint `name-rN+1`, shell to `kubectl rolling-update` —
  and `kubectl rolling-update` itself was removed from kubectl years
  ago; the Deployment controller has owned rollouts since. Definitions
  using `:rc` should move to Deployments (or ReplicaSets where the
  controller semantics are genuinely wanted).
- **Support for legacy locally-bootstrapped Kubernetes.** Matsuri once
  helped stand up a local cluster by hand — etcd, hyperkube, and SkyDNS
  on the dev machine — from before minikube and k3s made that someone
  else's job. The DNS add-on (`Matsuri::AddOns::DNS`, a SkyDNS/kube2sky
  deployment pinned to Kubernetes v1.0) and its `show dns` /
  `create dns` / `delete dns` verbs are removed, along with the
  bootstrap-era config keys: `etcd_version`, `hyperkube_version`,
  `kube2dns_version`, `skydns_version`, `kubernetes_cidr`, `etcd_addr`,
  `etcd_bind_addr`, `master_addr`, `master_bind_addr`, `api_servers`,
  `master_url`, `cluster_dns`, and `cluster_domain`. `dev_addr` stays —
  Endpoints definitions still default `public_ip_address` to it.
- **`let(:release)` and `maybe_param_name`.** Both served the client-side
  rolling-update machinery and lost their last consumer with it.
  `release` was the incrementing `-rN` rollout counter, defined on every
  resource (default `'0'`) and forwarded through pod options; nothing
  read it. `maybe_param_name` let `options[:name]` override the manifest
  name so a successor controller could be minted alongside the current
  one — no caller ever passed it to Deployment, ReplicaSet, or
  StatefulSet, and dropping it collapses their `default_metadata`
  overrides back to the base (which also restores `final_annotations`
  assembly on those three kinds). `maybe_param_replicas` stays for now:
  its real requirement — apply should not clobber live replica counts
  set by an HPA or manual scale — belongs to the planned read-back
  manifest transforms.

### Changed

- **ConfigMap applies normally.** The replace-instead-of-apply override
  dated to 2016 kubectl issues (kubernetes#32432, kubernetes#41711) that
  kubectl fixed years ago; `kubectl apply` handles configmaps fine. Apply
  now goes through `apply` like every other resource, and create seeds
  `last-applied-configuration` (`--save-config`) so the three-way merge
  has its base. Converge-by-recreate policy is unchanged.
- **Untagged stack converges propagate `latest` explicitly** (previously
  propagated nil and each workload class defaulted individually). Rendered
  output is unchanged; drift between per-class defaults is no longer
  possible.

### Added

- **`tests/` — a live-cluster probe harness.** `bin/minikube-start.sh`
  runs a dedicated `matsuri` minikube profile (`--keep-context`; vfkit
  driver on macOS), and `bin/probe-save-config.sh` pins the delivery
  semantics the seed model rests on: a create without `--save-config`
  keeps seeded fields out of last-applied, so ongoing applies of a
  manifest omitting them never prune them, and a controller takes
  ownership uncontested. minikube, kubectl, and (on macOS) vfkit join
  the nix devshell. These are delivery-semantics probes against a real
  API server, deliberately outside the rspec suite.
- **`present` pipelines on resources.** The same `present` grammar on
  `Kubernetes::Base`; default none. Through a stack, the two declaration
  sites merge into one pipeline — resource members first, stack members
  last. Both run; position is who sees the completed manifest: the
  resource's pipeline completes its self-knowledge, the stack's steps
  admit the finished manifest (where the server's own mutating admission
  sits relative to the client's payload). Direct resource verbs assemble
  the resource's own declarations alone, so a resource behaves
  identically converged directly or through an undeclared stack.
- **`present` pipelines on stacks.** `present(scenario, *members)`
  appends transform members to a scenario's pipeline — unlike `accept`,
  a scenario accumulates, and declaration order is member order. Members
  are presenter names, classes, Callables, or anything `#call`-able; the
  combinator vocabulary (`match`, `match_kind`, `match_deployments`) is
  available in the stack class body. Scenarios are intent regimes, not
  verbs: `:on_create` (brought into existence — `create`, recreate's
  create leg) and `:on_apply` (delivered to something existing —
  `apply`, `replace`, `diff`). `apply_via` picks how the payload
  travels; the scenario picks what it says — flipping delivery mechanism
  never changes which presenters run. Declarations ride to the
  `KubectlOps` boundary as pure data and each verb assembles its own
  scenario there; one site builds the presented payload for both diff
  and apply, so diff previews delivery through presenters. The empty
  pipeline is the identity: undeclared stacks send byte-identical
  payloads. Declarations never cross a stack boundary. Multi-doc
  manifests present per document. See docs/presenters.md. Boundary
  consequences: the module functions serialize payloads from
  `*_manifest_for_export` themselves (resources' `to_yaml`/
  `applied_to_yaml` overrides no longer shape delivery payloads, only
  `show`), and `converge` grew a `presents:` keyword — a literal
  trailing-hash `converge(r, restart: true)` call now needs braces.
  The client-side HashDiff compares the unpresented declaration;
  extending it through presenters is open.
- **`Matsuri::Presenter` — zero-config, context-free manifest steps.** A
  presenter is Manifest→Manifest: construction takes nothing, and
  parameterization happens before `#call` ever runs — definition lets
  filling a concern's declared holes, or declaration-time values closed
  over in a leaf `Callable`. Authors implement `#transform`; `#call` is
  framework-owned and makes the one deep boundary copy (Marshal, because
  the carrier is data), so input-never-mutated is a constraint rather
  than a convention, and a fresh instance per call scopes let memoization
  to a single manifest pass. The Kubernetes dialect is bare vocabulary
  inside `#transform`. Registry type `presenter`, definitions in
  `platform/presenters`, `Registry.presenter(name)` reader, bare classes
  equally valid. No built-ins ship yet.
- **`Transform::Kubernetes` — the manifest dialect.** Algebra + Env
  addressed to Kubernetes shapes: `set_env`, `set_all_env`,
  `set_resources` (strict, `EntryNotFound` on unknown container) and its
  curried `with_resources`, `set_label`, `append_volume`,
  `append_volume_mount`, `without_container`, and the node-affinity
  helpers over a well-known path constant — a misspelled path cannot
  exist at a call site. Pod now draws `expand_env` from `Transform::Env`
  instead of defining its own (`sorted_env` unchanged).
- **`Transform::Combinators` — Element→Element machinery.** `Match`
  applies its element only to manifests meeting the declared
  `{kind:, name:, namespace:}` criteria (the import-lookup addressing
  grammar; unknown keys are an error) and is the identity otherwise.
  The `Helpers` module carries the declaration vocabulary — `match`,
  `match_kind`, `match_deployments`; sugars grow on demand. Combinators
  are never registry-named: names cross the declaration boundary,
  machinery does not.
- **`Matsuri::Transform` — the pure manifest-transform strata.** Nothing
  under the namespace shells out; everything operates on plain data and
  composes as values. `Transform::Algebra` carries the path-addressed ops
  (`update_in`, `append_to`, `update_each`, `append_each`, `index_by_name`
  plus a strict `index_by_name!`, `except_entry_by_name`); contributions
  are values composed by `+`, never super()-chained deltas.
  `Transform::Callable` is the free monoid over transforms: `new` =
  identity, `new(label:) { }` = leaf, `new([members])` = composite, `+` =
  operand member-list concat into a new instance — never flattened, so a
  composite member stays one member and its label rides along as trace
  metadata. Coercion happens at construction and fails fast (#call-ables
  as-is; Symbol/String will name registered presenters). `Transform::Env`
  is the array↔map isomorphism for container env entries. Errors
  (`EntryNotFound`, `PathNotFound`) raise rather than log fatal. Inert in
  this phase: nothing calls the strata yet; `Concerns::ImportManifest` and
  Pod's env helpers are untouched until they rebuild on top. Law specs pin
  identity, associativity, zero-point, structural homomorphism,
  no-flatten representation, carrier-is-data, and the env round trip.
- **Acceptor collections on stacks.** `accept(collection, acceptor)`
  registers an acceptor (class or registry name) under a named collection;
  last declaration per collection wins, so re-declaring overrides. The
  collection name is the options key: each acceptor admits its own
  component of the invocation options, whole, and cannot see another
  collection's. `Matsuri::Stack` ships two built-ins — `:image_tag`
  carries the converge positional (a scalar, admitted whole, owning the
  `latest` default) and `:config` carries the stack-config artifact (the
  built-in is the empty acceptor: the collection is total, its surface is
  empty until a platform re-declares it).
- **stack-config.** `--stack-config=PATH` on `converge` and the new
  `show stack` / `diff stack` verbs names a YAML artifact for the stack
  instance being addressed. The CLI owns the boundary mapping — it loads
  the file and supplies data under the `:config` key; the stack itself
  never loads anything, so specs, controllers, and tooling construct
  stacks with data directly. A platform declares its accepted surface
  with `accept :config, <acceptor>`; resource members read the bound
  acceptor instance as `stack_config` (nil when a definition is invoked
  standalone), and the pod template forwards it, so pod definitions read
  the same binding. `Stack#delete!` instantiates members with the same
  options as converge, so a member whose identity derives from an
  accepted value addresses the same resource it created. No flag is the
  empty value and every declared read lands on its default; a flag with a
  bad path fails loudly, never falls back. stack-config never crosses a
  stack boundary — nested stack deps do not inherit it.
- **Acceptor** — a class that admits a value whose vocabulary matsuri does
  not own, such as a per-instance config artifact. The raw value arrives
  whole as `options`; `let` declarations are the accepted surface.
  Undeclared reads raise `NoMethodError`, unconsumed fields pass in
  silence, and every declared read carries its default, so the empty value
  is valid. Registry type `acceptor`, definitions in `platform/acceptors`,
  bare classes equally valid. See docs/acceptors.md and
  docs/design/acceptors.md.
- **Stack and acceptor documentation** — docs/stacks.md and
  docs/design/stacks.md (constraints and the properties they induce),
  docs/acceptors.md and docs/design/acceptors.md in the same form. Stack
  fixture and specs pin the converge sequence, member resolution, and
  per-stack `build_order` locality.
- **`rake docs:fmt`** — reformats docs/**/*.md through pandoc (gfm, 72
  columns, em-dashes and fence style preserved). Pandoc is included in the
  nix devshell.

### Fixed

- **Two latent `ImportManifest` bugs die by construction with the move
  to the strata.** `append_node_affinity` referenced a misspelled path
  name and raised `NameError` on every call; the dialect reads the
  `NODE_SELECTOR_TERMS_PATH` constant, so a misspelled path cannot
  exist at a call site. `set_env` from an imported manifest crashed
  because `update_kv` called `expand_env`, which only existed on Pod;
  both now live in `Transform::Env`, and the vendor-app fixture pins
  the repaired path end-to-end.

## [0.2.0] - 2026-10-24

Modernization release: the gem now targets Ruby >= 3.2 (developed and tested
on Ruby 4.0), drops ActiveSupport, and fixes a series of latent
manifest-rendering bugs — several of which change rendered output or diff
behavior. Review the Breaking and Changed sections before upgrading.

### Breaking

- **Ruby floor is now 3.2** (`required_ruby_version >= 3.2`). Developed and
  tested on Ruby 4.0. Ruby 2.x is no longer supported.
- **ActiveSupport is no longer a dependency.** The nine core_ext slices
  matsuri used (deep key transforms, `try`, `blank?`/`present?`/`presence`,
  `camelize`, `class_attribute`) are vendored in `matsuri/core_ext` as
  monkeypatches, so definition files keep their ambient grammar. Downstream
  repos that relied on matsuri transitively loading the rest of ActiveSupport
  must now require it themselves.
- **Pod security context lets renamed**: `priviledged` →
  `privileged`, `allow_priviledge_escalation` → `allow_privilege_escalation`.
  The old misspelled keys rendered field names the SecurityContext API does
  not have (latent while nil-and-compacted); definitions overriding the old
  lets must rename them.
- **`frozen_string_literal: true` across the codebase.** Strings returned by
  matsuri lets are frozen; definition code that mutated them in place will
  raise `FrozenError`.
- `awesome_print` removed (debugging residue in `imported_manifest`, never a
  declared dependency).

### Changed

Semantics changes — same DSL, different rendered output or runtime behavior:

- **`mem_request` now defaults to `mem_limit`** (previously defaulted to
  `cpu_limit`, a copy-paste error): pods defining only limits requested
  cpu-shaped quantities as memory.
- **Diff output is stricter.** The nil-vs-zero diff filter is now scoped to
  `spec.minReadySeconds` as originally intended (a missing `and` had made the
  path comparison a void expression). Declared zeros against a cluster nil —
  e.g. `runAsUser: 0` — now surface on all other paths.
- **Binding subjects render `apiGroup`** (camelCase) instead of a snake_case
  `api_group` field that lenient decoding silently dropped. ServiceAccount
  subjects had survived on the implicit `""` default; User and Group subjects
  would fail reconcile on strict decoding. The DSL-facing `api_group:`
  parameter is unchanged.
- **Roles without `bind_to` no longer emit bindings with empty subjects**;
  the subjects guard in `Binding#rbac_manifests` is honored, and subject-less
  bindings return nil (not false) so they compact away instead of crashing
  downstream key stringification.
- **ServiceAccount collections (`secrets`, `imagePullSecrets`) render only
  when non-empty.** An explicit empty list in applied configuration claims
  field ownership and deletes entries other actors add; an absent field makes
  no claim.
- **CronJob `timeZone`** renders the correct camelCase API field (the old
  snake_case key was invisible while unset, wrong the moment anyone set it);
  the job template spec now compacts, no longer emitting explicit nulls that
  strategic merge reads as field clears. The `sucess_policy` let is renamed
  `success_policy`.
- **Metadata default/override/final triple completed** in the cluster DSL:
  `final_metadata` is the user merge hook, and Binding, Role, ClusterRole,
  and ServiceAccount consume it. Rendered output is unchanged for existing
  definitions. `default_metadata` now compacts (cluster-scoped resources stop
  carrying a null `namespace` key into last-applied state), and namespaces
  coerce with `&.to_s` so symbol namespaces render identically on the YAML
  and JSON paths.
- Pod affinity `label_selector` compacts: affinity terms no longer render an
  explicit `matchExpressions` null.

### Added

- **`Concerns::Pods::SpreadPods`** — opt-in pod anti-affinity vocabulary for
  spreading same-labeled pods across nodes or zones. Not included in Pod by
  default; the includer selects a strategy via `let(:pod_anti_affinity)`.
  The zone topology key is its own let, defaulting to the well-known
  `topology.kubernetes.io/zone`.
- **`Concerns::Pods::SpreadTopology`** — opt-in topology spread constraint
  vocabulary complementing SpreadPods: constraints express balance (bounded
  replica skew per domain) where anti-affinity expresses exclusion. One
  `balanced_spread` builder specialized by topology-key lets; knobs ladder
  from shared defaults (`spread_max_skew`, `spread_when_unsatisfiable`) to
  per-domain overrides; strategies return lists and compose by
  concatenation. `zone_topology_key` is shared with SpreadPods so one
  override re-points both mechanisms.
- **CronJob** resource.
- **ImportedManifest** resource with `show`/`apply` command support, plus
  `ImportManifest` manifest-transform helpers and `ExportManifest`
  (refactored from `TransformManifest`).
- Pod template helpers; updated volume mount helper.
- Golden-manifest spec suite replacing the untouched gem-template skeleton:
  fixture-driven goldens for pod, deployment, stateful set, cron job, and the
  cluster RBAC DSL; specs for the vendored core_ext shims; load-order specs
  that touch each entry constant first in a fresh process (two load-order
  bugs surfaced during conversion); worked examples of bulkhead deployments
  over a shared podspec with a two-axis identity scheme (`app_role` ×
  `resource_class`) and a selector pairwise-disjointness law.
- `base64` gemspec dependency (left Ruby's default gems in 3.4; `secret` and
  `config_map` fail to load under bundler without it).
- Nix flake development environment.

### Fixed

- `Matsuri.define(:type, name, inherits: parent)` raised `ArgumentError` on
  Ruby 3+: keyword separation turned kwargs passed through the bare `*args`
  forwarder into a positional hash. The facade now mirrors
  `Registry.define`'s real signature.
- **`AggregatedClusterRole` is now actually defined.** Its file reopened
  `ClusterRole` instead of defining its own class, so the autoload constant
  never resolved — and loading the file would have replaced the regular
  ClusterRole manifest (aggregationRule in place of rules) for every cluster
  role.
- **The namespace/scope cluster DSL was broken end to end**: `scope()`
  referenced a wrong constant, discarded the child scope instead of appending
  it to definitions, and `require_namespace!` ignored the enclosing namespace
  scope its own error message offered. `aggregated_cluster_role()` now
  instantiates `AggregatedClusterRole`; it previously built a plain
  ClusterRole whose block would fail on the `match` helper.
- ServiceAccount `image_pull_secret` and `secret` helpers pushed into
  singular keys that initialize never created, raising `NoMethodError`; the
  storage and k8s fields are plural.
- `maybe_param_replicas` read `options[:relicas]` in all four workload
  classes, so passing `replicas` through options never worked.
- HPA: `average_value_metric_target` typo.
- Comparing a unit against an empty value no longer errors.
- Config: capital-F `Fail` in the `base_path` default raised `NoMethodError`
  instead of the intended message.
- Registry `options_for_type` listing: the basename/uniq/sort chain applied
  only to the second glob, so "Which <type>?" listings printed full paths for
  environment-dir definitions and never deduplicated.
- `Matsuri::Cmds::Cli` subclasses Thor but never required it, freeloading off
  the initializer; loading it first raised `NameError`.
- App: removed a duplicate `build!` stub silently shadowed by the later
  definition, and dead `call_on_failure` referencing a `failure_hooks` that
  was defined nowhere.
- `rlet/lazy_options` alone cannot resolve `Concern` under rlet 0.7;
  `app.rb` now requires the rlet umbrella so Registry/App load as a library
  without the CLI.

### Removed

- ActiveSupport dependency (see Breaking).
- `awesome_print` require (see Breaking).
- `.travis.yml` (targeted ruby 2.2.2 and bundler 1.10.6).

## [0.1.6] - 2022-03-24

Last release before this changelog was introduced. See git history.

[0.2.0]: https://github.com/matsuri-rb/matsuri/compare/v0.1.6...v0.2.0
[0.1.6]: https://github.com/matsuri-rb/matsuri/releases/tag/v0.1.6
