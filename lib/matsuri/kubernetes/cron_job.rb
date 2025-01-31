require 'active_support/core_ext/hash/compact'

module Matsuri
  module Kubernetes
    class CronJob < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::PodTemplate

      let(:api_version) { 'batch/v1' } # k8s v1.21
      let(:kind)        { 'CronJob' }  # https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/


      # Parameters passed from command line
      let(:image_tag)            { options[:image_tag] || 'latest' }

      # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#cronjobspec-v1-batch
      let(:spec) do
        {
          schedule:                   schedule,
          time_zone:                  time_zone,
          suspend:                    suspend,
          concurrencyPolicy:          concurrency_policy,
          successfulJobsHistoryLimit: successful_jobs_history_limit,
          failedJobsHistoryLimit:     failed_jobs_history_limit,
          startingDeadlineSeconds:    starting_deadline_seconds,

          jobTemplate: {
            metadata: job_template_metadata,
            spec: job_template_spec
          }.compact,
        }.compact
      end

      let(:concurrency_policy)            { nil } # 'Allow' | 'Forbid' | 'Replace', default: 'Allow'
      let(:failed_jobs_history_limit)     { nil } # non-negative integer, default: 1
      let(:schedule)                      { fail 'Must define let(:schedule)' } # string, cron schedule format
      let(:starting_deadline_seconds)     { nil } # seconds, integer, optional
      let(:successful_jobs_history_limit) { nil } # non-negative integer, default: 3
      let(:suspend)                       { nil } # boolean, default: false

      # k8s v1.27
      # See: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones
      # See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
      let(:time_zone)                     { nil } # string, TZ info, optional

      let(:job_template_metadata)         { { labels: pod_labels, annotations: pod_annotations } }


      # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#jobspec-v1-batch
      let(:job_template_spec) do
        {
          selector:                selector,
          completions:             completions,
          parallelism:             parallelism,
          activeDeadlineSeconds:   active_deadline_seconds,
          ttlSecondsAfterFinished: ttl_seconds_after_finished,
          backoffLimit:            backoff_limit,
          managedBy:               managed_by,
          manualSelector:          manual_selector,
          podReplacementPolicy:    pod_replacement_policy,
          suspend:                 job_template_suspend,

          template:                template, # defined in Matsuri::Concerns::PodTemplate

          # Indexed mode (for partitioning jobs), beta as of 1.31
          completionMode:          completion_mode,
          backoffLimitPerIndex:    backoff_limit_per_index,
          maxFailedIndexes:        max_failed_indexes,
          podFailurePolicy:        pod_failure_policy,
          successPolicy:           sucess_policy,
        }
      end

      let(:active_deadline_seconds)    { nil } # integer
      let(:backoff_limit)              { nil } # integer, default: 6
      let(:completions)                { nil } # null | integer
      let(:managed_by)                 { nil } # null | string
      let(:manual_selector)            { nil } # null | boolean
      let(:parallelism)                { nil } # null | integer
      let(:ttl_seconds_after_finished) { nil } # null | integer

      let(:selector)                   { nil } # This will be autopopulated by cronjob
      #let(:selector)                   { { matchLabels: match_labels, matchExpressions: match_expressions } }
      let(:match_labels)               { fail NotImplementedError, 'Must define let(:match_labels)' }
      let(:match_expressions)          { [] }

      let(:job_template_suspend)       { nil } # boolean, default: false


      let(:pod_replacement_policy)     { nil } # 'TerminatingOrFailed' | 'Failed'

      let(:completion_mode)            { nil } # 'NonIndexed' | 'Indexed', default: 'Indexed'
      let(:backoff_limit_per_index)    { nil } # integer
      let(:max_failed_indexes)         { nil } # null | integer

      # See: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#podfailurepolicy-v1-batch
      let(:pod_failure_policy)         { nil } # null | PodFailurePolicySpec

      # See: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#successpolicy-v1-batch
      let(:sucess_policy)              { nil } # null | SucessPolicySpec


      class << self
        def load_path
          Matsuri::Config.cron_jobs_path
        end

        def definition_module_name
          'CronJobs'
        end
      end
    end
  end
end
