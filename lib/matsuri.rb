require 'active_support/concern'

module Matsuri
  autoload :Initializer, 'matsuri/initializer'
  autoload :Config,      'matsuri/config'
  autoload :Platform,    'matsuri/platform'
  autoload :ShellOut,    'matsuri/shell_out'
  autoload :Registry,    'matsuri/registry'

  autoload :Task,        'matsuri/task'
  autoload :Cmd,         'matsuri/cmd'
  autoload :App,         'matsuri/app'

  module Kubernetes
    autoload :Base,                    'matsuri/kubernetes/base'

    # Core
    autoload :Pod,                     'matsuri/kubernetes/pod'
    autoload :ReplicationController,   'matsuri/kubernetes/replication_controller'
    autoload :Service,                 'matsuri/kubernetes/service'
    autoload :Endpoints,               'matsuri/kubernetes/endpoints'
    autoload :Ingress,                 'matsuri/kubernetes/ingress'
    autoload :Secret,                  'matsuri/kubernetes/secret'
    autoload :ConfigMap,               'matsuri/kubernetes/config_map'

    # Apps
    autoload :ReplicaSet,              'matsuri/kubernetes/replica_set'
    autoload :StatefulSet,             'matsuri/kubernetes/stateful_set'
    autoload :DaemonSet,               'matsuri/kubernetes/daemon_set'
    autoload :Deployment,              'matsuri/kubernetes/deployment'

    autoload :HorizontalPodAutoscaler, 'matsuri/kubernetes/horizontal_pod_autoscaler'

    # Persistent Storage
    autoload :PersistentVolume,        'matsuri/kubernetes/persistent_volume'
    autoload :PersistentVolumeClaim,   'matsuri/kubernetes/persistent_volume_claim'
    autoload :StorageClass,            'matsuri/kubernetes/storage_class'
  end

  module AddOns
    autoload :DNS, 'matsuri/add_ons/dns'
  end

  module Cmds
    autoload :Cli,      'matsuri/cmds/cli'
    autoload :Kubectl,  'matsuri/cmds/kubectl'
    autoload :Show,     'matsuri/cmds/show'
    autoload :Diff,     'matsuri/cmds/diff'
    autoload :Status,   'matsuri/cmds/status'
    autoload :Create,   'matsuri/cmds/create'
    autoload :Delete,   'matsuri/cmds/delete'
    autoload :Apply,    'matsuri/cmds/apply'
    autoload :Recreate, 'matsuri/cmds/recreate'
    autoload :Scale,    'matsuri/cmds/scale'

    autoload :Generate, 'matsuri/cmds/generate'
  end

  module Tasks
    autoload :Kubectl, 'matsuri/tasks/kubectl'
    autoload :Docker,  'matsuri/tasks/docker'
    autoload :Pod,     'matsuri/tasks/pod'
    autoload :Cluster, 'matsuri/tasks/cluster'
  end

  module Concerns
    autoload :TransformManifest,  'matsuri/concerns/transform_manifest'

    autoload :Awaiting,           'matsuri/concerns/awaiting'
    autoload :RegistryHelpers,    'matsuri/concerns/registry_helpers'
    autoload :Scalable,           'matsuri/concerns/scalable'
    autoload :PodTemplate,        'matsuri/concerns/pod_template'
  end

  module DSL
    module Cluster
      autoload :Scope,                 'matsuri/dsl/cluster/scope'

      autoload :Role,                  'matsuri/dsl/cluster/role'
      autoload :ClusterRole,           'matsuri/dsl/cluster/cluster_role'
      autoload :AggregatedClusterRole, 'matsuri/dsl/cluster/aggregated_cluster_role'
      autoload :Binding,               'matsuri/dsl/cluster/binding'

      autoload :ServiceAccount,        'matsuri/dsl/cluster/service_account'
    end

    module Concerns
      autoload :Metadata,        'matsuri/dsl/concerns/metadata'
      autoload :RbacRules,       'matsuri/dsl/concerns/rbac_rules'
      autoload :DefaultBinding,  'matsuri/dsl/concerns/default_binding'
      autoload :ManifestSet,     'matsuri/dsl/concerns/manifest_set'
    end
  end

  def self.define(*args, &blk)
    Matsuri::Registry.define(*args, &blk)
  end

  def self.environment
    Matsuri::Config.environment
  end

  def self.dev?
    Matsuri::Config.environment == 'dev'
  end

  def self.staging?
    Matsuri::Config.environment == 'staging'
  end

  def self.production?
    Matsuri::Config.environment == 'production'
  end

  def self.log(level, message = nil, &blk)
    case level
    when :fatal then
      log_output! message, &blk
      exit(1)
    when :error, :warn then log_output! message, &blk
    when :info         then log_output! message, &blk if Matsuri::Config.verbose
    when :debug        then log_output! message, &blk if Matsuri::Config.debug
    end
  end

  def self.log_output!(message)
    puts(message || yield)
  end
end
