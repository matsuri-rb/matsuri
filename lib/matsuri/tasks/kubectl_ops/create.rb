# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Imperative create of a rendered manifest payload. --save-config
      # seeds the last-applied-configuration annotation so a later
      # client-side apply gets its three-way merge; resources whose
      # ongoing delivery never consults it (e.g. replace-based) opt out.
      class Create
        include Matsuri::Task

        let(:input)       { options.fetch(:input) }
        let(:namespace)   { options.fetch(:namespace) }
        let(:description) { options.fetch(:description) }
        let(:save_config) { options.fetch(:save_config, true) }

        def run!
          puts "Creating #{description}".color(:yellow).bright if verbose
          puts input if debug
          kubectl! "create --save-config=#{save_config} -f -", input: input
        end
      end
    end
  end
end
