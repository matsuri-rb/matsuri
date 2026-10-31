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
      autoload :Delete,   'matsuri/tasks/kubectl_ops/delete'
      autoload :Recreate, 'matsuri/tasks/kubectl_ops/recreate'
      autoload :Scale,    'matsuri/tasks/kubectl_ops/scale'
      autoload :Status,   'matsuri/tasks/kubectl_ops/status'
      autoload :Get,      'matsuri/tasks/kubectl_ops/get'
      autoload :Diff,     'matsuri/tasks/kubectl_ops/diff'

      module_function

      def apply(resource, presents: {})
        task = resource.apply_via == :replace ? Replace : Apply
        task.new(input:       apply_payload(resource, presents),
                 namespace:   resource.namespace,
                 description: description_for(resource)).run!
      end

      def create(resource, presents: {})
        Create.new(input:       payload(resource.manifest_for_export, presents_for(resource, presents), :on_create),
                   namespace:   resource.namespace,
                   description: description_for(resource),
                   save_config: resource.save_config).run!
      end

      def delete(resource)
        Delete.new(identity_for(resource)).run!
      end

      def recreate(resource, presents: {})
        Recreate.new(identity_for(resource)
          .merge(input:       payload(resource.manifest_for_export, presents_for(resource, presents), :on_create),
                 description: description_for(resource),
                 save_config: resource.save_config)).run!
      end

      def scale(resource, replicas)
        Scale.new(identity_for(resource).merge(replicas: replicas)).run!
      end

      def status(resource)
        Status.new(identity_for(resource)).run!
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
      # invariant extends through presenters. When an SSA apply_via value
      # exists, this is where it routes --server-side through.
      def diff(resource, presents: {})
        Diff.new(input:       apply_payload(resource, presents),
                 namespace:   resource.namespace,
                 description: description_for(resource)).run!
      end

      # Lifecycle selection: the resource's converge_via policy picks the
      # task; the conditional lives here once, not as behavior flags
      # inside a task.
      def converge(resource, opts = {}, presents: {})
        verbose = Matsuri::Config.verbose

        case resource.converge_via
        when :recreate
          puts "Converging #{description_for(resource)} via recreate".color(:yellow) if verbose
          puts 'Rebuild not implemented. Recreating instead.'.color(:red).bright if opts[:rebuild]

          if opts[:restart] || opts[:rebuild]
            recreate(resource, presents: presents)
          else
            create(resource, presents: presents) unless exists?(resource)
          end
        else
          puts "Converging #{description_for(resource)} via apply".color(:yellow) if verbose
          puts 'Rebuild not implemented. Applying instead.'.color(:red).bright if opts[:rebuild]
          apply(resource, presents: presents)
        end
      end

      def apply_payload(resource, presents)
        payload(resource.applied_manifest_for_export, presents_for(resource, presents), :on_apply)
      end

      # Single merge, both declaration sites: the resource's own members
      # first (its pipeline completes its self-knowledge), stack members
      # appended (the boundary's steps admit the finished manifest).
      # Direct verbs arrive with no stack declarations, so a resource
      # behaves identically converged directly or through an undeclared
      # stack.
      def presents_for(resource, presents)
        own = resource.class.respond_to?(:presents) ? resource.class.presents || {} : {}
        (own.keys + presents.keys).map(&:to_sym).uniq.each_with_object({}) do |scenario, merged|
          merged[scenario] = Array(own[scenario]) + Array(presents[scenario])
        end
      end

      def payload(manifest, presents, scenario)
        serialize(presented(manifest, presents, scenario))
      end

      # The scenario's pipeline over the rendered manifest. Multi-doc
      # manifests (arrays) present per document, so match criteria select
      # documents with the same addressing grammar import lookup uses.
      # Presented output re-normalizes through deep_stringify_keys — the
      # same rule *_for_export already applied — so Maps and symbol keys
      # introduced by transforms never reach the payload.
      def presented(manifest, presents, scenario)
        pipeline = Matsuri::Transform::Callable.new(Array(presents[scenario]))
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
