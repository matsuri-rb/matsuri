# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Deletes a live object addressed by type/name.
      class Delete
        include Matsuri::Task

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }

        def run!
          puts "Deleting #{resource_type}/#{name}".color(:yellow).bright if verbose
          kubectl! "delete #{resource_type}/#{name}"
        end
      end
    end
  end
end
