module Matsuri
  autoload :Config,   'matsuri/config'
  autoload :ShellOut, 'matsuri/shell_out'
  autoload :Task,     'matsuri/task'
  autoload :Cmd,      'matsuri/cmd'
  autoload :Registry, 'matsuri/registry'

  module Kubernetes
    autoload :Base,                  'matsuri/kubernetes/base'
    autoload :Pod,                   'matsuri/kubernetes/pod'
    autoload :ReplicationController, 'matsuri/kubernetes/replication_controller'
    autoload :Service,               'matsuri/kubernetes/service'
  end

  module Cmds
    autoload :Cli,    'matsuri/cmds/cli'
    autoload :K8s,    'matsuri/cmds/k8s'
    autoload :Show,   'matsuri/cmds/show'
  end

  module Tasks
    autoload :Kubernetes, 'matsuri/tasks/kubernetes'
    autoload :Docker,     'matsuri/tasks/docker'
    autoload :Pod,        'matsuri/tasks/pod'
  end

  def self.define(type, name, &blk)
    Matsuri::Registry.define type, name, &blk
  end
end
