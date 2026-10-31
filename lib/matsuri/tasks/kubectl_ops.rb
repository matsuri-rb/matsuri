# frozen_string_literal: true

module Matsuri
  module Tasks
    # Delivery mechanism, scoped to kubectl shell-outs. One task per
    # verb+scenario; resources stay pure generators and the CLI selects
    # the task. A different delivery mechanism (direct API calls) would
    # be a sibling namespace, not a branch inside these.
    #
    # The module-level functions are the boundary: the single site that
    # derives task inputs from a rendered resource and reads its delivery
    # policy lets (apply_via, converge_via, save_config). Present
    # declarations ride in as pure data (scenario => member list) and the
    # verb assembles its own scenario's pipeline between the resource and
    # the task: create-regime verbs assemble :on_create, ongoing-delivery
    # verbs assemble :on_apply. The empty pipeline is the identity, so
    # payloads without declarations are byte-identical to the rendered
    # manifest.
    module KubectlOps
      autoload :Apply,    'matsuri/tasks/kubectl_ops/apply'
      autoload :Create,   'matsuri/tasks/kubectl_ops/create'
      autoload :Replace,  'matsuri/tasks/kubectl_ops/replace'
      autoload :ServerSideApply, 'matsuri/tasks/kubectl_ops/server_side_apply'
      autoload :Delete,   'matsuri/tasks/kubectl_ops/delete'
      autoload :Recreate, 'matsuri/tasks/kubectl_ops/recreate'
      autoload :Scale,    'matsuri/tasks/kubectl_ops/scale'
      autoload :Status,   'matsuri/tasks/kubectl_ops/status'
      autoload :RolloutStatus, 'matsuri/tasks/kubectl_ops/rollout_status'
      autoload :Get,      'matsuri/tasks/kubectl_ops/get'
      autoload :Diff,     'matsuri/tasks/kubectl_ops/diff'

      module_function

      # Under server-side delivery, a resource that is not yet live
      # routes through the seeding protocol instead: an ordinary apply
      # cannot land seeds, and nothing we send may ever own them. Every
      # later apply is the ordinary mechanism. field_manager rides to
      # every mechanism; only the server-side task reads it.
      def apply(resource, presenters: {})
        return Stacks.seed(resource, presenters: presenters) if server_side?(resource.apply_via) && !exists?(resource)

        apply_task_for(resource.apply_via)
          .new(input:         apply_payload(resource, presenters),
               namespace:     resource.namespace,
               description:   description_for(resource),
               field_manager: resource.field_manager).run!
      end

      # Routing for the apply_via delivery axis. Unknown values are
      # fatal — a silent fall-through to client-side apply would deliver
      # under the wrong merge semantics.
      def apply_task_for(apply_via)
        case apply_via
        when :apply             then Apply
        when :replace           then Replace
        when :server_side_apply then ServerSideApply
        else fail ArgumentError, "unknown apply_via: #{apply_via.inspect}"
        end
      end

      def server_side?(apply_via)
        apply_task_for(apply_via) == ServerSideApply
      end

      # Whether ongoing delivery under this apply_via consults the
      # last-applied-configuration annotation. Gates create/recreate's
      # --save-config: seeding last-applied when nothing consults it arms
      # a prune trap — a later client-side apply would three-way-merge
      # against the create payload, seeds included, and prune the seeds.
      def consults_last_applied?(apply_via)
        case apply_via
        when :apply                       then true
        when :replace, :server_side_apply then false
        else fail ArgumentError, "unknown apply_via: #{apply_via.inspect}"
        end
      end

      def create(resource, presenters: {})
        creation_task_for(resource, presenters).run!
      end

      # Bringing into existence: plain create for client-side delivery,
      # the seeding protocol for server-side. Returned unrun so recreate
      # can sequence it after teardown.
      def creation_task_for(resource, presenters)
        if server_side?(resource.apply_via)
          Stacks.seed_task(resource, presenters: presenters)
        else
          Create.new(input:       payload(resource.manifest_for_export, presenters_for(resource, presenters), :on_create),
                     namespace:   resource.namespace,
                     description: description_for(resource),
                     save_config: consults_last_applied?(resource.apply_via) && resource.save_config)
        end
      end

      def delete(resource)
        Delete.new(identity_for(resource)).run!
      end

      def recreate(resource, presenters: {})
        Recreate.new(identity_for(resource)
          .merge(description: description_for(resource),
                 create:      creation_task_for(resource, presenters))).run!
      end

      def scale(resource, replicas)
        Scale.new(identity_for(resource).merge(replicas: replicas)).run!
      end

      def status(resource)
        Status.new(identity_for(resource)).run!
      end

      def rollout_status(resource)
        RolloutStatus.new(identity_for(resource)).run!
      end

      def exists?(resource)
        Get.new(identity_for(resource)).exists?
      end

      # Current live manifest as a plain parsed hash; nil when the resource
      # is not on the cluster.
      def manifest(resource)
        Get.new(identity_for(resource)).manifest
      end

      # Server-side diff of the same payload apply would send: apply_payload
      # is one site, so the diff can never drift from the delivery — the
      # invariant extends through presenters. A server-side resource diffs
      # --server-side under the same field manager apply uses — a different
      # manager would preview a different conflict frontier. Conflicts
      # surface as errors (exit 2) and stay loud.
      def diff(resource, presenters: {})
        Diff.new(input:         apply_payload(resource, presenters),
                 namespace:     resource.namespace,
                 description:   description_for(resource),
                 server_side:   server_side?(resource.apply_via),
                 field_manager: resource.field_manager).run!
      end

      # Lifecycle selection: the resource's converge_via policy picks the
      # task; the conditional lives here once, not as behavior flags
      # inside a task.
      def converge(resource, opts = {}, presenters: {})
        verbose = Matsuri::Config.verbose

        case resource.converge_via
        when :recreate
          puts "Converging #{description_for(resource)} via recreate".color(:yellow) if verbose
          puts 'Rebuild not implemented. Recreating instead.'.color(:red).bright if opts[:rebuild]

          if opts[:restart] || opts[:rebuild]
            recreate(resource, presenters: presenters)
          else
            create(resource, presenters: presenters) unless exists?(resource)
          end
        else
          puts "Converging #{description_for(resource)} via apply".color(:yellow) if verbose
          puts 'Rebuild not implemented. Applying instead.'.color(:red).bright if opts[:rebuild]
          apply(resource, presenters: presenters)
        end
      end

      def apply_payload(resource, presenters)
        payload(resource.applied_manifest_for_export, presenters_for(resource, presenters), :on_apply)
      end

      # Single merge, both declaration sites: the resource's own members
      # first (its pipeline completes its self-knowledge), stack members
      # appended (the boundary's steps admit the finished manifest).
      # Direct verbs arrive with no stack declarations, so a resource
      # behaves identically converged directly or through an undeclared
      # stack.
      def presenters_for(resource, presenters)
        own = resource.class.respond_to?(:presenters) ? resource.class.presenters || {} : {}
        (own.keys + presenters.keys).map(&:to_sym).uniq.each_with_object({}) do |scenario, merged|
          merged[scenario] = Array(own[scenario]) + Array(presenters[scenario])
        end
      end

      def payload(manifest, presenters, scenario)
        serialize(presentation(manifest, presenters, scenario))
      end

      # The scenario's pipeline over the rendered manifest. Multi-doc
      # manifests (arrays) present per document, so match criteria select
      # documents with the same addressing grammar import lookup uses.
      # Presented output re-normalizes through deep_stringify_keys — the
      # same rule *_for_export already applied — so Maps and symbol keys
      # introduced by transforms never reach the payload.
      def presentation(manifest, presenters, scenario)
        pipeline = Matsuri::Transform::Callable.new(Array(presenters[scenario]))
        return manifest if pipeline.members.empty?

        if manifest.is_a?(Array)
          manifest.map { |doc| pipeline.call(Map.new(doc)).deep_stringify_keys }
        else
          pipeline.call(Map.new(manifest)).deep_stringify_keys
        end
      end

      # Multi-doc manifests serialize as concatenated YAML documents,
      # matching the imported-manifest export rule.
      def serialize(manifest)
        manifest.is_a?(Array) ? manifest.map(&:to_yaml).join('') : manifest.to_yaml
      end

      def description_for(resource)
        "#{resource.resource_type}/#{resource.name}"
      end

      def identity_for(resource)
        { resource_type: resource.resource_type, name: resource.name, namespace: resource.namespace }
      end
    end
  end
end
