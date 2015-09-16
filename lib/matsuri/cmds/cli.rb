
module Matsuri
  module Cmds
    class Cli < Thor
      include Matsuri::Cmd

      class_option :config,  aliases: :c, type: :string,  default: File.join(ENV['PWD'], 'config', 'matsuri.rb')
      class_option :verbose, aliases: :v, type: :boolean, default: false
      class_option :debug,                type: :boolean, default: false

      desc "k8s SUBCOMMAND ...ARGS", "manage Kubernetes"
      subcommand 'k8s', Matsuri::Cmds::K8s

      desc 'show SUBCOMMAND ...ARGS', 'show or display artifacts'
      subcommand 'show', Matsuri::Cmds::Show
    end
  end
end
