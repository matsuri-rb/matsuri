# frozen_string_literal: true

require 'hashdiff'
require 'unit'

module Matsuri
  module Concerns
    # Client-side diff: compares the declared manifest against a current
    # manifest handed in by the caller, with comparison noise filtered out.
    # Pure computation — fetching the current manifest, presenting the
    # declaration, and printing deltas belong to Tasks::HashDiff. The
    # filter helpers are the per-resource override surface: a definition
    # that knows about additional noise paths overrides them here.
    #
    # This diff answers "what drifted relative to my declaration". The
    # server-side diff (kubectl diff) answers "what will the cluster do
    # with this, admission injections included". Both are kept.
    module Diffable
      # current is a plain string-keyed hash, as parsed from kubectl
      # output. desired overrides the comparison basis — Tasks::HashDiff
      # hands in the presented declaration so drift reads against what
      # apply would send; default is the raw declaration.
      def diff(current, desired: nil)
        desired ||= JSON.parse(to_json)

        Hashdiff.diff(current, desired) do |path, current_value, desired_value|
          filter_comparison_values(path, current_value, desired_value)
        end
      end

      # Focused variant: compares only the primary container, projected out
      # of both manifests by primary_container_path. Unfiltered — the noise
      # filters address whole-manifest paths, which do not occur inside a
      # container.
      def primary_container_diff(current, desired: nil)
        unless primary_container_path
          Matsuri.log :fatal, "#{resource_type}/#{name} does not declare let(:primary_container_path)"
        end

        desired ||= JSON.parse(to_json)

        Hashdiff.diff current.dig(*primary_container_path), desired.dig(*primary_container_path)
      end

      def filter_comparison_values(path, current_value, desired_value)
        if empty_assignment_to_empty?(current_value, desired_value) or
           readonly_path?(path) or
           always_changed_path?(path) or
           default_value_assigned_nothing?(path, current_value, desired_value) or
           unit_comparison_is_equal?(current_value, desired_value)
           # (
           #   path.start_with?("metadata.") and
           #   path !~ /^metadata\.\b(name|labels|namespace)\b/
           # ) or
          true
        else
          :perform_normal_comparison end
      end

      def empty_assignment_to_empty?(current_value, desired_value)
        empty_value?(current_value) and empty_value?(desired_value)
      end

      def readonly_path?(path)
        [
          'status',
        ].member?(path)
      end

      def always_changed_path?(path)
        [
           'metadata.annotations.kubectl.kubernetes.io/last-applied-configuration',
           'metadata.annotations.kubernetes.io/change-cause',
        ].member?(path)
      end

      def default_value_assigned_nothing?(path, current_value, desired_value)
        # standard case of empty value desired but current value is
        # atomic/predefined
        (
          empty_value?(desired_value) and
            not (current_value.is_a?(Hash) or current_value.is_a?(Array))
        ) or

        # volumeMounts are not readOnly by default, making a setting of false
        # redundant
        (
          path =~ /volumeMount.*readOnly/ and
          current_value.nil? and
          desired_value == false
        ) or

        # minReadySeconds is 0 by default but not presented as such
        (
          path == 'spec.minReadySeconds' and
          current_value.nil? and
          desired_value == 0
        )
      end

      def unit_comparison_is_equal?(current_value, desired_value)
        # Unit cannot handle nil values, so if one one of the values
        # are empty, then return false (beacuse it is not comparable)
        return false if empty_value?(current_value) || empty_value?(desired_value)
        # Only strings carry quantities; Object#=~ is gone as of Ruby 3.2,
        # so anything else must bail before the match
        return false unless current_value.is_a?(String) and desired_value.is_a?(String)

        if current_value =~ /^\d+\s*[A-Za-z]+$/ or desired_value =~ /^\d+\s*[A-Za-z]+$/
          (
            includes_unit?(current_value) and
            includes_unit?(desired_value) and
            Unit(current_value) == Unit(desired_value)
          ) or
          (
            Unit(current_value + 'B') == Unit(desired_value + 'B')
          )
        else
          false
        end
      end

      def includes_unit?(value)
        Unit(value)
        true
      rescue TypeError
        false
      end

      def empty_value?(value)
        value.nil? or value == {} or value == [] or value == ""
      end
    end
  end
end
