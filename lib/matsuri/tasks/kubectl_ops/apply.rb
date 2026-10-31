# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Client-side apply of a rendered manifest payload. The payload is
      # whatever the caller finished rendering — single-doc or multi-doc
      # YAML — so one task serves generated and imported manifests alike.
      class Apply
        include Matsuri::Task

        let(:input)       { options.fetch(:input) }
        let(:namespace)   { options.fetch(:namespace) }
        let(:description) { options.fetch(:description) }

        def run!
          puts "Applying (create or update) #{description}".color(:yellow).bright if verbose
          puts input if debug
          kubectl! 'apply -f -', input: input
        end
      end
    end
  end
end
