# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Displays the live state of an object addressed by type/name.
      class Status
        include Matsuri::Task

        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }

        def run!
          kubectl! "get #{resource_type}/#{name} -o wide"
        end
      end
    end
  end
end
