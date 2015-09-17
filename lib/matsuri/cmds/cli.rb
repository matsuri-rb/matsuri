
module Matsuri
  module Cmds
    class Cli < Thor
      include Matsuri::Cmd

      class_option :config,  aliases: :c, type: :string,  default: File.join(ENV['PWD'], 'config', 'matsuri.rb')
      class_option :verbose, aliases: :v, type: :boolean
      class_option :debug,                type: :boolean

      desc "k8s SUBCOMMAND ...ARGS", "manage Kubernetes"
      subcommand 'k8s', Matsuri::Cmds::K8s

      desc 'show SUBCOMMAND ...ARGS', 'show resource'
      subcommand 'show', Matsuri::Cmds::Show

      desc 'start SUBCOMMAND ...ARGS', 'start resource'
      subcommand 'start', Matsuri::Cmds::Start

      desc 'reload SUBCOMMAND ...ARGS', 'reload resource'
      subcommand 'reload', Matsuri::Cmds::Reload

      desc 'stop SUBCOMMAND ...ARGS', 'stop resource'
      subcommand 'stop', Matsuri::Cmds::Stop
    end
  end
end
