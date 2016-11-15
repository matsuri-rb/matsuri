
module Matsuri
  module Cmds
    class Cli < Thor
      include Matsuri::Cmd

      class_option :config,  aliases: :c, type: :string, default: File.join(ENV['PWD'], 'config', 'matsuri.rb')
      class_option :verbose, aliases: :v, type: :boolean
      class_option :debug,   aliases: :D, type: :boolean
      class_option :environment, aliases: :e, type: :string, default: ENV['MATSURI_ENVIRONMENT']

      desc "k8s SUBCOMMAND ...ARGS", "manage Kubernetes [deprecated]"
      #subcommand 'k8s', Matsuri::Cmds::K8s
      def k8s
        puts "k8s is going away. Use minikube or nanokube"
        exit(1)
      end

      desc 'show SUBCOMMAND ...ARGS', 'show resource'
      subcommand 'show', Matsuri::Cmds::Show
      map describe: :show

      desc 'status SUBCOMMAND ...ARGS', 'resource status'
      subcommand 'status', Matsuri::Cmds::Status
      map top: :status

      desc 'create SUBCOMMAND ...ARGS', 'create resource (kubectl create)'
      subcommand 'create', Matsuri::Cmds::Create
      map start: :create

      desc 'apply SUBCOMMAND ...ARGS', 'create or update resource (kubectl apply)'
      subcommand 'apply', Matsuri::Cmds::Apply
      map reload: :apply

      desc 'rebuild', 'Not Implementd'
      def rebuild
        puts "Rebuild not implemented yet"
        exit (1)
      end

      desc 'recreate SUBCOMMAND ...ARGS', 'recreate resource'
      subcommand 'recreate', Matsuri::Cmds::Recreate
      map restart: :recreate

      desc 'delete SUBCOMMAND ...ARGS', 'delete resource'
      subcommand 'delete', Matsuri::Cmds::Delete
      map stop: :delete

      desc 'converge APP_NAME', 'Idempotently converges an app and all dependencies'
      option :restart, type: :boolean, default: false
      def converge(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.app(name).new(image_tag: image_tag).converge!(opt)
        end
      end

      desc 'scale SUBCOMMAND ...ARGS', 'scale resource'
      subcommand 'scale', Matsuri::Cmds::Scale

      desc 'rollout RC_NAME [TAG]', 'Rolls out a new image for a replication controller'
      def rollout(name, image_tag = nil)
        with_config do |opt|
          Matsuri::Registry.rc(name).new.rollout!(image_tag, opt)
        end
      end

      desc 'migrate APP_NAME VERSION', 'Migrates an app to VERSION'
      def migrate(name, version)
        with_config do |opt|
          Matsuri::Registry.app(name).new.migrate!(version, opt)
        end
      end

      desc 'update APP_NAME [VERSION]', 'Updates an app to VERSION'
      option :skip_migrations
      def update(name, version = nil)
        with_config do |opt|
          Matsuri::Registry.app(name).new.update!(version, opt)
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

      desc 'sh! APP_NAME', 'Shells into an app container as root'
      option :pod,  aliases: :p, type: :string
      def sh!(name, *args)
        with_config do |opt|
          opt[:root] = true
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

      desc 'build APP_NAME', 'Builds docker image for app'
      option :dev,         type: :boolean,  default: false
      option :version,     type: :string
      option :branch,      type: :string
      option :github_user, type: :string
      option :repo,        type: :string
      def build(name)
        with_config do |opt|
          Matsuri::Registry.app(name).new.build!(opt)
        end
      end

      desc 'push APP_NAME', 'Pushes docker image for app'
      option :dev,     type: :boolean, default: false
      option :version, type: :string,  default: 'latest'
      def push(name)
        with_config do |opt|
          Matsuri::Registry.app(name).new.push!(opt)
        end
      end
    end
  end
end
