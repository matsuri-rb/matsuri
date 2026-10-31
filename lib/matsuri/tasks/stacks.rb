# frozen_string_literal: true

module Matsuri
  module Tasks
    # Stack-scope delivery acts: protocols that sequence the kubectl
    # verbs into one intent. KubectlOps maps one verb to one task; these
    # compose them.
    module Stacks
      autoload :Seed, 'matsuri/tasks/stacks/seed'

      module_function

      # Creation protocol for a server-side-applied resource: seeded
      # create, declared apply, cede. See Seed.
      def seed(resource, presenters: {})
        seed_task(resource, presenters: presenters).run!
      end

      # The constructed, unrun task — recreate sequences it after
      # teardown.
      def seed_task(resource, presenters: {})
        ops = Matsuri::Tasks::KubectlOps
        Seed.new(ops.identity_for(resource).merge(
          seeded:        ops.payload(resource.manifest_for_export, ops.presenters_for(resource, presenters), :on_create),
          declared:      ops.apply_payload(resource, presenters),
          description:   ops.description_for(resource),
          field_manager: resource.field_manager))
      end
    end
  end
end
