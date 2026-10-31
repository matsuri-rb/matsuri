# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Full replacement of a live object with a rendered payload.
      class Replace
        include Matsuri::Task

        let(:input)       { options.fetch(:input) }
        let(:namespace)   { options.fetch(:namespace) }
        let(:description) { options.fetch(:description) }

        def run!
          puts "Replacing #{description}".color(:yellow).bright if verbose
          puts input if debug
          kubectl! 'replace -f -', input: input
        end
      end
    end
  end
end
