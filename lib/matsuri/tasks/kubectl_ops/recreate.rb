# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Delete-then-create lifecycle: tears down the live object if
      # present, waits until the deletion lands, then creates from the
      # rendered payload. The payload must be rendered before this task
      # runs — deletion severs anything the render would have read back.
      class Recreate
        include Matsuri::Task
        include Matsuri::Concerns::Awaiting

        let(:input)         { options.fetch(:input) }
        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }
        let(:description)   { options.fetch(:description, "#{resource_type}/#{name}") }
        let(:save_config)   { options.fetch(:save_config, true) }

        let(:identity) { { resource_type: resource_type, name: name, namespace: namespace } }

        def run!
          if Get.new(identity).exists?
            Delete.new(identity).run!
            awaiting!('resource deletion', interval: 0.5) { !Get.new(identity).exists? }
          end

          Create.new(input: input, namespace: namespace, description: description, save_config: save_config).run!
        end
      end
    end
  end
end
