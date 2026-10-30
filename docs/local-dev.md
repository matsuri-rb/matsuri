# Local Development

Matsuri grew up as a local development harness: build an image, point
the pod at your working tree, converge, and iterate. These workflows are
still in the gem. This page documents them as they exist, along with
where the ecosystem has since produced better tools.

## Docker Build and Push

A stack can own its image lifecycle. The `build` and `push` verbs drive
hooks that the stack definition supplies — the gem provides the wiring,
the platform provides the meaning:

```bash
matsuri dev build myapp --version v42 --branch main
matsuri dev push  myapp --version v42
```

```ruby
Matsuri.define :stack, 'myapp' do
  def build!(opt = {})
    docker! "build -t myapp:#{opt[:version] || 'latest'} #{config.docker_path}"
  end

  def push!(opt = {})
    docker! "push myapp:#{opt[:version] || 'latest'}"
  end
end
```

Without a definition, both hooks fail with a message saying so; there is
no default build behavior. `build` accepts `--dev`, `--version`,
`--branch`, `--github-user`, and `--repo`; `push` accepts `--dev` and
`--version`. What the options mean is up to the hook.

Conventional paths for build inputs live in `Matsuri::Config`:

- `docker_path` (`docker/`) — Dockerfiles and build contexts
- `build_path` (`build/`) — build output
- `images_path` (`platform/images`) — image definitions

## Live Mounts

The iterate-without-rebuilding loop: mount the working tree into the pod
with a hostPath volume, so edits on the host appear in the running
container. Pod definitions get path helpers that resolve against the
platform repo:

- `src_path('myapp')` — `src/myapp` under the repo; the working tree
- `cache_path('bundle')` — `.cache/bundle`; persistent caches for gems,
  node_modules, and other artifacts that should outlive the pod
- `base_path('etc/myapp.conf')` — any path under the repo
- `host_path_volume(name, path)` — the hostPath volume entry

```ruby
Matsuri.define :pod, 'myapp-dev' do
  let(:volumes) do
    [
      host_path_volume('src',   src_path('myapp')),
      host_path_volume('gems',  cache_path('bundle'))
    ]
  end

  let(:container) do
    {
      name:         'myapp',
      image:        'myapp:latest',
      volumeMounts: [
        { name: 'src',  mountPath: '/app' },
        { name: 'gems', mountPath: '/bundle' }
      ]
    }
  end
end
```

This pattern assumes the kubelet can reach the host filesystem — true
for single-node local clusters where the node is your machine (or a VM
with the repo mounted into it). On Docker Desktop for Mac, hostPath file
I/O crosses the VM boundary and has historically been slow enough to
defeat the purpose; Linux with a local cluster is where this loop
shines.

## Interactive Verbs: sh, console, status

> **Deprecation notice**: [k9s](https://k9scli.io/) is a better tool for
> all of this — live resource views, shell into any container, logs,
> port-forwards, and resource metrics in one TUI, without any stack
> definition support. These verbs may be deprecated in a future release.

`sh` and `console` shell into a stack's primary workload. Like `build!`,
they drive hooks the stack definition supplies — `sh!(opt, args)` and
`console!(opt, args)` — and fail with a message when undefined:

```bash
matsuri dev sh myapp              # shell, as the container user
matsuri dev sh myapp -p web-0     # pick a pod
matsuri dev sh! myapp             # shell, as root
matsuri dev console myapp         # app console (rails c, iex, etc.)
```

`sh` accepts `--root`/`-r`, `--user`/`-u`, and `--pod`/`-p`; `sh!` is
`sh` with root; `console` accepts `--root`, `--user`, and `--pod`. The
distinction is convention: `sh` promises a shell, `console` promises the
application's REPL — what command actually runs is the hook's call.

`status` reports on resources, with per-resource subcommands and two
kubectl-top wrappers:

```bash
matsuri dev status stack myapp
matsuri dev status pod myapp-web
matsuri dev status pods           # kubectl top pods
matsuri dev status nodes          # kubectl top nodes
matsuri dev top pods              # top is an alias for status
```

Resource-level `status` calls the resource's `status!`, which a
definition may implement; the Stack base class requires the definition
to supply it.
