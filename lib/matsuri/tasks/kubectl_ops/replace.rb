# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Full replacement of a live object with a rendered payload.
      #
      # One value of the apply_via delivery axis, mutually exclusive with
      # apply and server-side apply: a resource chooses it with
      # `let(:apply_via) { :replace }`. No built-in
      # declares it; the cost of choosing it is that replace clobbers
      # fields other writers own and never consults
      # last-applied-configuration — so apply is the default for a reason.
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
