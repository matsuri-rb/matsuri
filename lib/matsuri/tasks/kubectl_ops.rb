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
    # policy lets (apply_via, converge_via, save_config). Post-generation
    # manifest transforms slot in here, between the resource and the task.
    module KubectlOps
      autoload :Apply,    'matsuri/tasks/kubectl_ops/apply'
      autoload :Create,   'matsuri/tasks/kubectl_ops/create'
      autoload :Replace,  'matsuri/tasks/kubectl_ops/replace'
      autoload :Delete,   'matsuri/tasks/kubectl_ops/delete'
      autoload :Recreate, 'matsuri/tasks/kubectl_ops/recreate'
      autoload :Scale,    'matsuri/tasks/kubectl_ops/scale'
      autoload :Get,      'matsuri/tasks/kubectl_ops/get'

      module_function

      def apply(resource)
        task = resource.apply_via == :replace ? Replace : Apply
        task.new(input:       resource.applied_to_yaml,
                 namespace:   resource.namespace,
                 description: description_for(resource)).run!
      end

      def create(resource)
        Create.new(input:       resource.to_yaml,
                   namespace:   resource.namespace,
                   description: description_for(resource),
                   save_config: resource.save_config).run!
      end

      def delete(resource)
        Delete.new(identity_for(resource)).run!
      end

      def recreate(resource)
        Recreate.new(identity_for(resource)
          .merge(input:       resource.to_yaml,
                 description: description_for(resource),
                 save_config: resource.save_config)).run!
      end

      def scale(resource, replicas)
        Scale.new(identity_for(resource).merge(replicas: replicas)).run!
      end

      def exists?(resource)
        Get.new(identity_for(resource)).exists?
      end

      # Lifecycle selection: the resource's converge_via policy picks the
      # task; the conditional lives here once, not as behavior flags
      # inside a task.
      def converge(resource, opts = {})
        verbose = Matsuri::Config.verbose

        case resource.converge_via
        when :recreate
          puts "Converging #{description_for(resource)} via recreate".color(:yellow) if verbose
          puts 'Rebuild not implemented. Recreating instead.'.color(:red).bright if opts[:rebuild]

          if opts[:restart] || opts[:rebuild]
            recreate(resource)
          else
            create(resource) unless exists?(resource)
          end
        else
          puts "Converging #{description_for(resource)} via apply".color(:yellow) if verbose
          puts 'Rebuild not implemented. Applying instead.'.color(:red).bright if opts[:rebuild]
          apply(resource)
        end
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
