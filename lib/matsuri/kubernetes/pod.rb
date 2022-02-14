require 'active_support/core_ext/hash/compact'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'json'

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/Alias
module Matsuri
  module Kubernetes
    class Pod < Matsuri::Kubernetes::Base
      let(:api_version) { 'v1' }
      let(:kind)        { 'Pod' }

      # Overridables
      let(:spec) do
        {
          containers:     containers,
          initContainers: init_containers,
          volumes:        volumes,

          imagePullSecrets: image_pull_secrets,

          # Networking and Host
          hostname:    hostname,
          subdomain:   subdomain,
          dnsConfig:   dns_config,
          dnsPolicy:   dns_policy,
          hostAliases: host_aliases,
          hostIPC:     host_ipc,
          hostNetwork: host_network,

          # Scheduling
          nodeName:                  node_name,
          nodeSelector:              node_selector,
          affinity:                  affinity,
          tolerations:               tolerations,
          priority:                  priority,
          priorityClassName:         priority_class_name,
          schedulerName:             scheduler_name,
          topologySpreadConstraints: topology_spread_constraints,

          # Lifecylce
          readinessGates:                readiness_gates,
          restartPolicy:                 restart_policy,
          activeDeadlineSeconds:         active_deadline_seconds,
          terminationGracePeriodSeconds: termination_grace_period_seconds,

          # Security
          hostPID:                       host_pid,
          shareProcessNamespace:         share_process_namespace,
          securityContext:               pod_security_context,
          serviceAccountName:            service_account_name,
          automountServiceAccountToken:  automount_service_account_token
        }.compact
      end

      # Get image tag from the command line
      let(:image_tag)          { options[:image_tag] || 'latest' }

      let(:containers)         { [container] }
      let(:init_containers)    { nil }
      let(:volumes)            { [volume] }
      let(:image_pull_secrets) { [] }

      # Scheduling
      let(:node_name)                   { nil }
      let(:node_selector)               { { } }
      let(:tolerations)                 { [toleration].compact }
      let(:toleration)                  { nil }
      let(:affinity)                    { { nodeAffinity: node_affinity, podAffinity: pod_affinity, podAntiAffinity: pod_anti_affinity }.compact }
      let(:node_affinity)               { nil } # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#nodeaffinity-v1-core
      let(:pod_affinity)                { nil } # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#podaffinity-v1-core
      let(:pod_anti_affinity)           { nil } # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#podantiaffinity-v1-core
      let(:priority)                    { nil }
      let(:priority_class_name)         { nil }
      let(:scheduler_name)              { nil }
      let(:topology_spread_constraints) { nil } # https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/

      # Networking and Host
      let(:hostname)           { nil } # https://kubernetes.io/docs/admin/dns/
      let(:subdomain)          { nil }
      let(:dns_config)         { nil }
      let(:dns_policy)         { nil }
      let(:host_aliases)       { nil }
      let(:host_ipc)           { nil }
      let(:host_network)       { nil }

      # Lifecycle
      let(:readiness_gates)                  { nil }
      let(:restart_policy)                   { 'Always' }
      let(:active_deadline_seconds)          { nil }
      let(:termination_grace_period_seconds) { nil }

      # Security and Execution Context
      let(:host_pid)                         { nil }
      let(:share_process_namespace)          { nil }
      let(:service_account_name)             { nil }
      let(:automount_service_account_token)  { nil }

      # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#podsecuritycontext-v1-core
      let(:pod_security_context) do
        {
          runAsUser:          pod_run_as_user,
          runAsGroup:         pod_run_as_group,
          runAsNonRoot:       pod_run_as_non_root,
          seLinuxOptions:     pod_se_linux_options,
          fsGroup:            fs_group,
          supplementalGroups: supplemental_groups,
          sysctls:            sysctls
        }.compact
      end

      let(:pod_run_as_user)      { nil }
      let(:pod_run_as_group)     { nil }
      let(:pod_run_as_non_root)  { nil }
      let(:pod_se_linux_options) { nil }
      let(:fs_group)             { nil }
      let(:supplemental_groups)  { nil }
      let(:sysctls)              { nil }

      # Default container
      let(:container)   { fail NotImplementedError, 'Must define let(:container)'}
      let(:volume)      { fail NotImplementedError, 'Must define let(:volume)' }

      let(:primary_container) { containers.first[:name] }
      let(:primary_image)     { fail NotImplementedError, 'Must define let(:primary_image) for deployment or replication controller' }

      # Resources for default container
      let(:resources)          { { requests: resource_requests, limits: resource_limits } }
      let(:resource_requests)  { { cpu: cpu_request, memory: mem_request }.compact }
      let(:resource_limits)    { { cpu: cpu_limit,   memory: mem_limit  }.compact }

      # We want to make sure all limits are defined
      let(:cpu_limit)   { fail NotImplementedError, 'Must define let(:cpu_limit)' }
      let(:mem_limit)   { fail NotImplementedError, 'Must define let(:mem_limit)' }
      let(:cpu_request) { cpu_limit }
      let(:mem_request) { cpu_limit }

      # Default container security context
      let(:security_context) do
        {
          runAsUser:                 run_as_user,
          runAsGroup:                run_as_group,
          runAsNonRoot:              run_as_non_root,
          priviledged:               priviledged,
          allowPriviledgeEscalation: allow_priviledge_escalation,
          seLinuxOptions:            se_linux_options,
          capabilities:              capabilities
        }.compact
      end

      let(:run_as_user)                 { nil }
      let(:run_as_group)                { nil }
      let(:run_as_non_root)             { nil }
      let(:priviledged)                 { nil }
      let(:allow_priviledge_escalation) { nil }
      let(:se_linux_options)            { nil }
      let(:capabilities)                { nil }

      ### Helpers

      # Pods are practically useless with using apply. When we converge, we want
      # to recreate instead. Pods unamaged by rc, rs, or deployment are more useful
      # in dev mode than anywhere else
      def converge!(opts = {})
        converge_by_recreate!(opts)
      end

      # Helper methods
      def up?
        cmd = kubectl "get #{resource_type}/#{name} -o json", echo_level: :debug, no_stdout: true
        Matsuri.log :fatal, "Unable to get status for #{resource_type}/#{name}" unless cmd.status.success?
        pod_json = JSON.parse(cmd.stdout)
        Matsuri.log :debug, pod_json['status']
        return false unless pod_json['status']['phase'] == 'Running'
        return false unless pod_json['status']['containerStatuses'].any?
        pod_json['status']['containerStatuses'].all? { |c| c['ready'] == true }
      end

      def config_file(path)
        File.join config.config_path, path
      end

      def cache_path(path)
        File.join config.cache_path, path
      end

      def src_path(path)
        File.join config.src_path, path
      end

      def base_path(path)
        File.join config.base_path, path
      end

      # Ruby 2.0+ uses ordered hashes
      def expand_env(hash)
        hash.map do |k,v|
          if v.is_a?(Hash)
            { name: k, valueFrom: v }
          else
            { name: k, value: v.to_s }
          end
        end
      end

      def env_from_secret(name:, key:)
        { secretKeyRef: { name: name, key: key } }
      end

      def env_from_config_map(name:, key:)
        { configMapKeyRef: { name: name, key: key } }
      end

      def env_from_field_ref(path:)
        { fieldRef: { fieldPath: path } }
      end

      def env_from_resource(resource:, container: nil, divisor: nil)
        { resourceFieldRef: { resource: resource, containerName: container, divisor: divisor } }
      end

      def sorted_env(hash)
        expand_env(hash).sort { |a,b| a[:name] <=> b[:name] }
      end

      def port(num, protocol: 'TCP', name: nil, host_ip: nil, host_port: nil)
        {
          name:          name.try(:to_s),
          containerPort: num,
          protocol:      protocol.to_s,
          hostIP:        host_ip,
          hostPort:      host_port
        }.compact
      end

      def mount(name, path, read_only: false)
        { name: name, mountPath: path, readOnly: read_only }
      end

      def host_path_volume(name, host_path)
        { name: name, hostPath: { path: host_path } }
      end

      def empty_dir_volume(name, medium: nil)
        { name: name, emptyDir: { medium: medium }.compact }
      end

      def tmpfs_volume(name)
        empty_dir_volume(name, medium: 'Memory')
      end

      def secret_volume(name, secret_name:, items: nil, default_mode: nil)
        { name: name, secret: { secretName: secret_name, items: items, defaultMode: default_mode }.compact }
      end

      def secret_item(key, path, mode: nil)
        { key: key, path: path, mode: mode }.compact
      end

      def config_map_volume(name, config_map_name: nil, items: nil, default_mode: nil)
        config_map_name ||= name
        { name: name, configMap: { name: config_map_name, items: items, defaultMode: default_mode }.compact }
      end

      def gce_volume(name, pd_name:, fs_type: 'ext4')
        { name: name, gcePersistentDisk: { pdName: pd_name, fsType: fs_type } }
      end

      def label_selector(match_labels: nil, match_expressions: nil)
        {
          matchLabels:      match_labels,
          matchExpressions: match_expressions.present? ? Array(match_expressions) : nil
        }
      end

      def match_labels_selector(matcher)
        label_selector(match_labels: matcher)
      end

      def match_expressions_selector(matcher)
        label_selector(match_expressions: matcher)
      end

      def match_expression(key:, operator:, values: nil)
        { key: key, operator: operator, values: values }.compact
      end

      def tolerate(key: nil, value: nil, operator: 'Equal', effect: nil, toleration_seconds: nil)
        {
          key:               key,
          value:             value,
          effect:            effect,
          operator:          operator,
          tolerationSeconds: toleration_seconds
        }.compact
      end

      # Helper to generate pod affinity term
      # Defaults to node name for topology key, and empty namespaces
      def pod_affinity_term(match_labels: nil, match_expressions: nil, namespaces: [], topology_key: 'kubernetes.io/hostname')
        {
          labelSelector: label_selector(match_labels: match_labels, match_expressions: match_expressions),
          namespaces:    namespaces,
          topologyKey:   topology_key
        }.compact
      end

      alias_method :affinity_term, :pod_affinity_term

      def weighted_pod_affinity_term(weight: 100, match_labels: nil, match_expressions: nil, namespaces: [], topology_key: 'kubernetes.io/hostname')
        {
          weight: weight,
          podAffinityTerm: pod_affinity_term(match_labels: match_labels, match_expressions: match_expressions, namespaces: namespaces, topology_key: topology_key)
        }
      end

      alias_method :weighted_affinity_term, :weighted_pod_affinity_term

      def preferred_during_scheduling_ignored_during_execution(*weighted_affinity_terms)
        { preferredDuringSchedulingIgnoredDuringExecution: weighted_affinity_terms }
      end

      alias_method :preferred_during_scheduling, :preferred_during_scheduling_ignored_during_execution

      def required_during_scheduling_ignored_during_execution(*affinity_terms)
        { requiredDuringSchedulingIgnoredDuringExecution: affinity_terms }
      end

      alias_method :required_during_scheduling, :required_during_scheduling_ignored_during_execution

      def topology_spread_constraint(opts = {})
        {
          maxSkew:           opts[:max_skew],
          topologyKey:       opts[:topology_key],
          whenUnsatisfiable: opts[:when_unsatisfiable],
          labelSelector:     opts[:label_selector]
        }.compact
      end

      def spread_by_node(opts = {})
        topology_spread_constraint({topology_key: 'kubernetes.io/hostname'}.merge(opts))
      end

      def spread_by_zone(opts = {})
        topology_spread_constraint({topology_key: 'topology.kubernetes.io/zone'}.merge(opts))
      end

      def spread_by_region(opts = {})
        topology_spread_constraint({topology_key: 'topology.kubernetes.io/region'}.merge(opts))
      end

      # Helpers

      def diff!(opt = {})
        deltas = opt[:primary_container] ? primary_container_diff : diff
        print_diff(deltas)
      end

      def containers_diff
        current = current_manifest(raw: true)
        Matsuri.log :fatal, "Cannot fetch current manifest for #{resource_type}/#{name}" unless current

        desired = JSON.parse(to_json)

        Hashdiff.diff current['spec']['containers'][0], desired['spec']['containers'][0]
      end

      class << self
        def load_path
          Matsuri::Config.pods_path
        end

        def definition_module_name
          'Pods'
        end
      end
    end
  end
end
