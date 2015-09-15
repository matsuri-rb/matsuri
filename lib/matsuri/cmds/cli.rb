
module Matsuri
  module Cmds
    class Cli < Thor
      class_option :verbose, type: :boolean, default: false
      class_option :debug,   type: :boolean, default: false

      desc "k8s SUBCOMMAND ...ARGS", "manage Kubernetes"
      subcommand 'k8s', Matsuri::Cmds::K8s

      desc 'pod SUBCOMMAND ...ARGS', 'manage pods'
      subcommand 'pod', Matsuri::Cmds::Pod
    end
  end
end
