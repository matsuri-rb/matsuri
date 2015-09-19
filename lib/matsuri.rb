module Matsuri
  autoload :Config,   'matsuri/config'
  autoload :ShellOut, 'matsuri/shell_out'
  autoload :Registry, 'matsuri/registry'

  autoload :Task,     'matsuri/task'
  autoload :Cmd,      'matsuri/cmd'
  autoload :App,      'matsuri/app'

  module Kubernetes
    autoload :Base,                  'matsuri/kubernetes/base'
    autoload :Pod,                   'matsuri/kubernetes/pod'
    autoload :ReplicationController, 'matsuri/kubernetes/replication_controller'
    autoload :Service,               'matsuri/kubernetes/service'
    autoload :Endpoints,             'matsuri/kubernetes/endpoints'
  end

  module AddOns
    autoload :DNS, 'matsuri/add_ons/dns'
  end

  module Cmds
    autoload :Cli,     'matsuri/cmds/cli'
    autoload :K8s,     'matsuri/cmds/k8s'
    autoload :Show,    'matsuri/cmds/show'
    autoload :Start,   'matsuri/cmds/start'
    autoload :Reload,  'matsuri/cmds/reload'
    autoload :Restart, 'matsuri/cmds/restart'
    autoload :Stop,    'matsuri/cmds/stop'
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
