# Boot

This covers what happens between invoking `matsuri` and a command
running: how invocation works and where your own code enters. The repo
layout itself is in [Setup](setup.md); the constraints behind this
design — the promise layers and the properties they induce — are in
[docs/design/boot.md](design/boot.md).

## Invocation

    matsuri <environment> <verb> ...

Invoke from the repo base — where the Gemfile is, in the manner of
terraform or chef. The environment is the first positional argument and
has no other source: there is no environment variable and no
significance to the binary's name. What you typed is what runs.
[Setup](setup.md) covers how an environment name binds to a kubectl
context and namespace.

## The Wrapper

The repo's `bin/matsuri` makes the Gemfile's version binding unavoidable
from any shell. Pin and exec is its entire job:

```bash
#!/bin/bash -e
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export BUNDLE_GEMFILE="${SCRIPT_DIR}/../Gemfile"
exec bundle exec matsuri "$@"
```

A per-environment entry point is argument injection in a sibling script,
not wrapper logic:

```bash
#!/bin/bash -e
# bin/staging
exec "$(dirname "$0")/matsuri" staging "$@"
```

## The Boot Sequence

1.  **Discovery.** Walk up from the working directory to the nearest
    `config/matsuri.rb`; that directory is the repo base. No repo found
    is a fatal error before any command logic runs.
2.  **Load path.** The repo's `lib/` is prepended to the load path.
    Everything after this point may require the repo's own code.
3.  **Environment.** The first positional argument, verbatim.
4.  **Configuration.** `config/matsuri.rb` is loaded for `Config`
    overrides, then the platform config (`config/platform.rb`, plus a
    repo-local `.platform.rb` if present) for environment definitions.
    Configuration is declarative — defaults and definitions, no
    requires.
5.  **Activation.** `config/initializer.rb` is required, if present.
    This is the one site that loads code: plugins and your extension
    library. It runs after configuration, so it may branch on the
    environment or any resolved setting.
6.  **Dispatch.** The remaining arguments go to the CLI.

## Your Extension Library

Name a module after your organization, give it a file in `lib/`, and
autoload your mixins from it:

```ruby
# lib/yourco.rb
module Yourco
  module Pods
    autoload :Healthcheck, 'yourco/pods/healthcheck'
  end
end
```

```ruby
# config/initializer.rb
require 'yourco'
```

Because boot put `lib/` on the load path before the initializer runs,
this works the same under `bundle exec`, a bare gem install, or a
checkout. The repo needs no gemspec. The mixins themselves are ordinary
concerns carrying `let()` definitions — see [Resources](resources.md)
for how they compose into definitions.

## Plugins

The Gemfile declares what exists; the initializer activates it:

```ruby
# Gemfile
gem 'matsuri', '~> 0.3'
gem 'matsuri-traefik'
```

```ruby
# config/initializer.rb
require 'matsuri/traefik'
```

A gem declared but never required costs nothing and breaks nothing —
adding it to the Gemfile is not yet a decision about boot.
