# frozen_string_literal: true

module Matsuri
  module Tasks
    module KubectlOps
      # Full replacement of a live object with a rendered payload.
      #
      # Legacy mechanism: no built-in resource routes here anymore (ConfigMap
      # did, working around 2016-era kubectl apply gaps). Replace clobbers
      # fields other writers own and never consults last-applied-configuration,
      # so prefer apply. A resource that genuinely needs it opts in with
      # `let(:apply_via) { :replace }`.
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
