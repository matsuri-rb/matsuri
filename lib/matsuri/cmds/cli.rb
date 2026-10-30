# frozen_string_literal: true

require 'thor'

module Matsuri
  module Cmds
    class Cli < Thor
      include Matsuri::Cmd

      # Don't want to write code to _not_ load in the config, so not going to do it here
      #class_option :config,  aliases: :c, type: :string, default: File.join(Matsuri::Config.base_path, 'config', 'matsuri.rb')
      class_option :verbose, aliases: :v, type: :boolean
      class_option :debug,   aliases: :D, type: :boolean

      desc 'generate SUBCOMMAND ...ARGS', 'generate Matsuri scaffolding'
      subcommand 'generate', Matsuri::Cmds::Generate

      desc 'kubectl SUBCOMMAND ...ARGS', 'manage kubectl configs'
      subcommand 'kubectl', Matsuri::Cmds::Kubectl

      desc 'show SUBCOMMAND ...ARGS', 'show resource'
      subcommand 'show', Matsuri::Cmds::Show
      map describe: :show

      desc 'diff SUBCOMMAND ...ARGS', 'diff resource (show what would be applied)  '
      subcommand 'diff', Matsuri::Cmds::Diff

      desc 'status SUBCOMMAND ...ARGS', 'resource status'
      subcommand 'status', Matsuri::Cmds::Status
      map top: :status

      desc 'create SUBCOMMAND ...ARGS', 'create resource (kubectl create)'
      subcommand 'create', Matsuri::Cmds::Create
      map start: :create

      desc 'apply SUBCOMMAND ...ARGS', 'create or update resource (kubectl apply)'
      subcommand 'apply', Matsuri::Cmds::Apply

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

      desc 'converge STACK_NAME [IMAGE_TAG]', 'Idempotently converges a stack and all dependencies'
      option :restart, type: :boolean, default: false
      option :stack_config, type: :string, banner: 'PATH'
      def converge(name, image_tag = nil)
        with_config do |opt|
          Matsuri::Registry.stack(name)
            .new(image_tag: image_tag, config: stack_config_data(opt))
            .converge!(opt)
        end
      end

      desc 'reconcile', 'Reconcile and converge cluster-wide resources, such as RBAC and NetworkPolicy'
      def reconcile
        with_config do |opt|
          Matsuri::Tasks::Cluster.new.reconcile!(opt)
        end
      end

      desc 'reload STACK_NAME', 'Reloads a stack without recreating underlying pods'
      def reload(name, image_tag = nil)
        with_config do |opt|
          Matsuri::Registry.stack(name).new(image_tag: image_tag).reload!(opt)
        end
      end

      desc 'scale SUBCOMMAND ...ARGS', 'scale resource'
      subcommand 'scale', Matsuri::Cmds::Scale

      desc 'migrate STACK_NAME VERSION', 'Migrates a stack to VERSION'
      def migrate(name, version)
        with_config do |opt|
          Matsuri::Registry.stack(name).new.migrate!(version, opt)
        end
      end

      desc 'update STACK_NAME [VERSION]', 'Updates a stack to VERSION'
      option :skip_migrations
      def update(name, version = nil)
        with_config do |opt|
          Matsuri::Registry.stack(name).new.update!(version, opt)
        end
      end

      desc 'sh STACK_NAME', 'Shells into a stack container'
      option :root, aliases: :r, type: :boolean, default: false
      option :user, aliases: :u, type: :string
      option :pod,  aliases: :p, type: :string
      def sh(name, *args)
        with_config do |opt|
          Matsuri::Registry.stack(name).new.sh!(opt, args)
        end
      end

      desc 'sh! STACK_NAME', 'Shells into a stack container as root'
      option :pod,  aliases: :p, type: :string
      def sh!(name, *args)
        with_config do |opt|
          opt[:root] = true
          Matsuri::Registry.stack(name).new.sh!(opt, args)
        end
      end

      desc 'console STACK_NAME', 'Gets to the console of a stack'
      option :root, type: :boolean, default: false
      option :user, type: :string
      option :pod,  aliases: :p, type: :string
      def console(name, *args)
        with_config do |opt|
          Matsuri::Registry.stack(name).new.console!(opt, args)
        end
      end

      desc 'build STACK_NAME', 'Builds docker image for stack'
      option :dev,         type: :boolean,  default: false
      option :version,     type: :string
      option :branch,      type: :string
      option :github_user, type: :string
      option :repo,        type: :string
      def build(name)
        with_config do |opt|
          Matsuri::Registry.stack(name).new.build!(opt)
        end
      end

      desc 'push STACK_NAME', 'Pushes docker image for stack'
      option :dev,     type: :boolean, default: false
      option :version, type: :string,  default: 'latest'
      def push(name)
        with_config do |opt|
          Matsuri::Registry.stack(name).new.push!(opt)
        end
      end
    end
  end
end
