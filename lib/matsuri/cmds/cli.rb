
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

      desc 'build', 'Not Implementd'
      def build
        puts "Build not implemented yet"
        exit (1)
      end

      desc 'start SUBCOMMAND ...ARGS', 'start resource'
      subcommand 'start', Matsuri::Cmds::Start

      #desc 'reload SUBCOMMAND ...ARGS', 'reload resource'
      #subcommand 'reload', Matsuri::Cmds::Reload
      desc 'reload', 'Not Implementd'
      def reload
        puts "Reload not implemented yet"
        exit (1)
      end

      desc 'rebuild', 'Not Implementd'
      def rebuild
        puts "Rebuild not implemented yet"
        exit (1)
      end

      desc 'restart SUBCOMMAND ...ARGS', 'restart resource'
      subcommand 'restart', Matsuri::Cmds::Restart

      desc 'stop SUBCOMMAND ...ARGS', 'stop resource'
      subcommand 'stop', Matsuri::Cmds::Stop

      desc 'converge APP_NAME', 'Idempotently converges an app and all dependencies'
      def converge(name)
        with_config do |opt|
          Matsuri::Registry.app(name).new.converge!(opt)
        end
      end
    end
  end
end
