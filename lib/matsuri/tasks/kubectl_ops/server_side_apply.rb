# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Server-side apply of a rendered manifest payload: the apiserver
      # merges by field ownership under the given field manager instead
      # of the client's three-way last-applied merge.
      #
      # One value of the apply_via delivery axis
      # (`let(:apply_via) { :server_side_apply }`). Never passes
      # --force-conflicts: a conflict marks the frontier where another
      # manager owns a field this declaration sends, and forcing through
      # it is an incident-time human judgment — the escape hatch is raw
      # kubectl, not a flag here.
      class ServerSideApply
        include Matsuri::Task

        let(:input)         { options.fetch(:input) }
        let(:namespace)     { options.fetch(:namespace) }
        let(:description)   { options.fetch(:description) }
        let(:field_manager) { options.fetch(:field_manager) }

        def run!
          puts "Applying (server-side) #{description}".color(:yellow).bright if verbose
          puts input if debug
          kubectl! "apply --server-side --field-manager=#{field_manager} -f -", input: input
        end
      end
    end
  end
end
