# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Working toward 0.3.0.

### Breaking

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

### Removed

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

### Changed

- **Untagged stack converges propagate `latest` explicitly** (previously
  propagated nil and each workload class defaulted individually). Rendered
  output is unchanged; drift between per-class defaults is no longer
  possible.

### Added

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
