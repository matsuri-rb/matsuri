module Matsuri
  autoload :ShellOut, 'matsuri/shell_out'
  autoload :Task,     'matsuri/task'

  module Cmds
    autoload :Cli,    'matsuri/cmds/cli'
    autoload :K8s,    'matsuri/cmds/k8s'
    autoload :Pod,    'matsuri/cmds/pod'
  end

  module Tasks
    autoload :Kubernetes, 'matsuri/tasks/kubernetes'
    autoload :Docker,     'matsuri/tasks/docker'
    autoload :Pod,        'matsuri/tasks/pod'
  end
end
