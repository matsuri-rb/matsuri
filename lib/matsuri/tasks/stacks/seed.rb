# frozen_string_literal: true

module Matsuri
  module Tasks
    module Stacks
      # Creation protocol for resources delivered by server-side apply.
      #
      # A seeded field (the boot image, an initial replica count) must
      # exist at birth but never rides the ongoing declaration — the
      # declared payload omits it, so delivery never contests whoever
      # rolls it. Server-side apply cannot create such an object safely
      # on its own: an apply against empty managedFields attributes every
      # pre-existing field to the synthetic manager before-first-apply,
      # which never applies again and so never relinquishes — the first
      # changed-value apply conflicts forever. The protocol below is the
      # surviving creation path; it and the refuted alternatives are
      # pinned by tests/bin/probe-ssa.sh.
      #
      # Three steps, each loud on failure:
      # 1. create as <field_manager>-seed (the seed owner) with the
      #    seeded payload. The create stamps a manager regardless, so
      #    inject a known one: a converge that dies mid-protocol strands
      #    an object whose managedFields still read as ours. No
      #    --save-config — a seeded last-applied is a prune trap for any
      #    later client-side apply.
      # 2. Ordinary declared server-side apply as the field manager.
      #    Equal values co-own; managedFields is never empty, so no
      #    before-first-apply ghost.
      # 3. Cede: remove the seed owner's managedFields entry with an
      #    atomic test+remove JSON patch. Ownership IS the managedFields
      #    content — deleting the entry is the transfer. The field
      #    manager ends sole owner of the declared fields; seeds end
      #    unowned until a controller or deliverer takes them.
      class Seed
        include Matsuri::Task

        REMOVAL_ATTEMPTS = 3

        let(:seeded)        { options.fetch(:seeded) }
        let(:declared)      { options.fetch(:declared) }
        let(:resource_type) { options.fetch(:resource_type) }
        let(:name)          { options.fetch(:name) }
        let(:namespace)     { options.fetch(:namespace) }
        let(:description)   { options.fetch(:description, "#{resource_type}/#{name}") }
        let(:field_manager) { options.fetch(:field_manager) }
        let(:seed_owner)    { "#{field_manager}-seed" }

        def run!
          puts "Seeding #{description}".color(:yellow).bright if verbose
          create!
          apply!
          cede!
        end

        def create!
          puts seeded if debug
          kubectl! "create --field-manager=#{seed_owner} -f -", input: seeded
        end

        def apply!
          KubectlOps::ServerSideApply.new(input:         declared,
                                          namespace:     namespace,
                                          description:   description,
                                          field_manager: field_manager).run!
        end

        def cede!
          last = nil
          REMOVAL_ATTEMPTS.times do
            idx = seed_owner_index
            Matsuri.log(:fatal, "#{description}: no managedFields entry for #{seed_owner}") if idx.nil?
            last = kubectl "patch #{resource_type}/#{name} --type=json -p '#{removal_patch(idx)}'", no_stdout: true
            return if last.status.success?
          end
          Matsuri.log :fatal, "#{description}: could not remove #{seed_owner} after #{REMOVAL_ATTEMPTS} attempts\n#{last.stderr}"
        end

        # Fresh read per attempt: entry order is not stable, and the test
        # op in the patch turns a stale index into a rejection, never a
        # wrong removal.
        def seed_owner_index
          cmd = kubectl! "get #{resource_type}/#{name} --show-managed-fields -o json", echo_level: :debug, no_stdout: true
          JSON.parse(cmd.stdout)['metadata'].fetch('managedFields', []).index { |entry| entry['manager'] == seed_owner }
        end

        def removal_patch(idx)
          [{ op: 'test',   path: "/metadata/managedFields/#{idx}/manager", value: seed_owner },
           { op: 'remove', path: "/metadata/managedFields/#{idx}" }].to_json
        end
      end
    end
  end
end
