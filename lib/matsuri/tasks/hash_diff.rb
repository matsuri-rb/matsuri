# frozen_string_literal: true

require 'rainbow/ext/string'

module Matsuri
  module Tasks
    # Client-side diff: fetches the current manifest, asks the resource for
    # the filtered deltas (Concerns::Diffable), and prints them. Sibling to
    # KubectlOps rather than inside it — the comparison happens here, kubectl
    # is only the fetch. The server-side counterpart (KubectlOps::Diff,
    # wrapping kubectl diff) shows what the cluster will make of the
    # manifest, admission injections included; this one shows drift relative
    # to the declaration with the noise filtered. Both are kept.
    class HashDiff
      include Matsuri::Task

      let(:resource)          { options.fetch(:resource) }
      let(:primary_container) { options[:primary_container] }
      let(:presenters)        { options[:presenters] || {} }

      def run!
        current = Matsuri::Tasks::KubectlOps.manifest(resource)
        unless current
          Matsuri.log :fatal, "Cannot fetch current manifest for #{Matsuri::Tasks::KubectlOps.description_for(resource)}"
        end

        deltas =
          if primary_container
            resource.primary_container_diff(current, desired: desired_manifest)
          else
            resource.diff(current, desired: desired_manifest)
          end
        print_diff(deltas)
      end

      # The declaration through the same :on_apply pipeline apply
      # assembles, over the same basis this diff has always used — so
      # drift reads against what apply would send, never against a step a
      # presenter owns. The JSON round trip is the comparison
      # normalization diff always applied to the declaration.
      def desired_manifest
        ops = Matsuri::Tasks::KubectlOps
        presentation = ops.presentation(resource.manifest_for_export,
                                        ops.presenters_for(resource, presenters), :on_apply)
        JSON.parse(presentation.to_json)
      end

      def print_diff(deltas)
        deltas.each do |line|
          color = case line[0]
                  when '-' then :red
                  when '+' then :green
                  when '~' then :yellow
                  end
          puts line.join(' ').color(color).bright
        end
      end
    end
  end
end
