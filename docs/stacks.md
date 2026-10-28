# Stacks

Stacks are groupings of resources that are managed together.

## Defining Stacks

Stacks are defined in `platform/stacks` with a DSL that defines
resources that are needed. It takes an argument that references
a Matsuri definition and type.

```
### Insert example bulkhead, with service, service account, config_maps
```

At this time, there is no way to define dependencies. Applying the
manifest is performed in sequence.


## Operation

```
matsuri <env> converge <stack name>
```

The converge operation applies changes in sequence as defined by the
the stack

## Stack Config

We can pass a configuration yaml file into the stack that can be
referenced by resources. This is intended to parameterize an entire
stack. The main use-case is to support dynamic environments used
within software development lifecycle.
