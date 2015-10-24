
module Matsuri
  module Cmds
    class Cli < Thor
      include Matsuri::Cmd

      class_option :config,  aliases: :c, type: :string, default: File.join(ENV['PWD'], 'config', 'matsuri.rb')
      class_option :verbose, aliases: :v, type: :boolean
      class_option :debug,   aliases: :D, type: :boolean
      class_option :environment, aliases: :e, type: :string, default: ENV['MATSURI_ENVIRONMENT']

      desc "k8s SUBCOMMAND ...ARGS", "manage Kubernetes"
      subcommand 'k8s', Matsuri::Cmds::K8s

      desc 'show SUBCOMMAND ...ARGS', 'show resource'
      subcommand 'show', Matsuri::Cmds::Show

      desc 'build APP_NAME', 'builds an app'
      def build(name)
        # Build is problematic, running make files. It's not
        # entirely necessary, so will implement this later if
        # there is enough demand for it.
        puts "build not implemented yet"
        exit (1)
        with_config do |opt|
          Matsuri::Registry.app(name).new.build!(opt)
        end
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
      option :restart, type: :boolean, default: false
      def converge(name)
        with_config do |opt|
          Matsuri::Registry.app(name).new.converge!(opt)
        end
      end

      desc 'sh APP_NAME', 'Shells into an app container'
      option :root, aliases: :r, type: :boolean, default: false
      option :user, aliases: :u, type: :string
      option :pod,  aliases: :p, type: :string
      def sh(name, *args)
        with_config do |opt|
          Matsuri::Registry.app(name).new.sh!(opt, args)
        end
      end

      desc 'console APP_NAME', 'Gets to the console of an app'
      option :root, type: :boolean, default: false
      option :user, type: :string
      option :pod,  aliases: :p, type: :string
      def console(name, *args)
        with_config do |opt|
          Matsuri::Registry.app(name).new.console!(opt, args)
        end
      end
    end
  end
end
