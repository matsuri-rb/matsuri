# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Delete-then-create lifecycle: tears down the live object if
      # present, waits until the deletion lands, then runs the creation
      # task the boundary selected — plain create for client-side
      # delivery, the seeding protocol for server-side. The payload must
      # be rendered before this task runs — deletion severs anything the
      # render would have read back.
      class Recreate
        include Matsuri::Task
        include Matsuri::Concerns::Awaiting

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }
        let(:description)   { options.fetch(:description, "#{resource_type}/#{name}") }
        let(:create)        { options.fetch(:create) }

        let(:identity) { { resource_type: resource_type, name: name, namespace: namespace } }

        def run!
          if Get.new(identity).exists?
            Delete.new(identity).run!
            awaiting!('resource deletion', interval: 0.5) { !Get.new(identity).exists? }
          end

          create.run!
        end
      end
    end
  end
end
