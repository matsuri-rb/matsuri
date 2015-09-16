
module Matsuri
  module Cmds
    class Cli < Thor
      include Matsuri::Cmd

      class_option :config,  aliases: :c, type: :string,  default: File.join(ENV['PWD'], 'config', 'matsuri.rb')
      class_option :verbose, aliases: :v, type: :boolean, default: false
      class_option :debug,                type: :boolean, default: false

      desc "k8s SUBCOMMAND ...ARGS", "manage Kubernetes"
      subcommand 'k8s', Matsuri::Cmds::K8s

      desc 'pod SUBCOMMAND ...ARGS', 'manage pods'
      subcommand 'pod', Matsuri::Cmds::Pod

      desc 'config', 'displays config'
      def config
        require 'json'
        with_config do |opt|
          puts opt.inspect if opt[:debug]
          puts JSON.pretty_generate(Matsuri::Config.save(true))
        end
      end
    end
  end
end
