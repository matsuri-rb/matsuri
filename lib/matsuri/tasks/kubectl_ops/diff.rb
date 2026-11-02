# frozen_string_literal: true

require 'rainbow/ext/string'

module Matsuri
  module Tasks
    module KubectlOps
      # Server-side diff: the apiserver dry-runs the payload through
      # defaulting and admission, and kubectl prints live-vs-admitted.
      # Companion to Tasks::HashDiff, which shows drift relative to the
      # declaration; this one shows what the cluster will actually do
      # with the manifest, admission injections included.
      #
      # kubectl diff exit codes carry meaning: 0 = no differences,
      # 1 = differences found, >1 = error. Only >1 is a failure, and
      # silence on no-differences is kubectl's own convention.
      class Diff
        include Matsuri::Task

        let(:input)         { options.fetch(:input) }
        let(:namespace)     { options.fetch(:namespace) }
        let(:description)   { options.fetch(:description) }
        let(:server_side)   { options.fetch(:server_side, false) }
        let(:field_manager) { options.fetch(:field_manager, nil) }

        def run!
          puts "Diffing (live vs admitted) #{description}".color(:yellow).bright if verbose
          puts input if debug

          cmd = kubectl "diff#{server_side_args} -f -", input: input
          if cmd.exitstatus > 1
            $stderr.print "ERROR: #{cmd.exitstatus}\nSTDOUT:\n#{cmd.stdout}\n\nSTDERR:\n#{cmd.stderr}\n".color(:red).bright
            exit 1
          end

          puts "No changes for #{description}".color(:yellow) if verbose && cmd.exitstatus.zero?
        end

        # The manager must be the one apply delivers under, or the
        # preview shows a different conflict frontier than delivery hits.
        def server_side_args
          server_side ? " --server-side --field-manager=#{field_manager}" : ''
        end
      end
    end
  end
end
