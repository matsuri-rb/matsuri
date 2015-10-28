require 'map'
require 'active_support/core_ext/class/attribute'
require 'rainbow/ext/string'
require 'rlet/lazy_options'

module Matsuri
  class App
    include Let
    include RLet::LazyOptions
    include Matsuri::ShellOut
    include Matsuri::Concerns::RegistryHelpers

    class_attribute :build_order, :failure_hooks

    # Defines a list of deps, used to  to idempotently converge Kubernetes
    # resources. Generally, you will add a an app as a dep for resources you are
    # sharing with other apps, while directly referencing Kubernetes resources
    # for things this app is directly respondible for.
    #
    # Examples:
    # needs :app,     'postgresql-95'
    # needs :app,     'redis-28'
    # needs :app,     'load-balancer'
    # needs :rc,      'rails-app-worker'
    # needs :rc,      'rails-app'
    # needs :service, 'rails-app'
    class << self
      def needs(type, name, on_failure: nil)
        self.build_order ||= []
        self.build_order << [type.to_sym, name.to_s]
        on_failure(type, name, on_failure) if on_failure
      end

      def on_failure(type, name, hook_name)
        self.failure_hooks ||= Map.new
        self.failure_hooks.set(type, name, hook_name)
      end

      def config_file(path)
        File.join(Matsuri::Config.config_path, path)
      end
    end

    # Override this. This command defines how to build the app,
    # including all dependencies
    def build!
      fail NotImplementedError, 'Must implement #build!'
    end

    # Override this. This command defines how all the app depenencies
    # are started, such as services, endpoints, replication controllers, etc.
    def start!
      converge! # Most of the time, we want to converge
    end

    # Override this. This command defines how all app dependencies are stopped
    def stop!
      self.class.build_order.each do |(type, name)|
        if type == :app
          puts "Skipping app #{name}"
          next
        end

        dep(type, name).new.stop!
      end
    end

    def restart!
      stop!
      start!
    end

    def rebuild!
      build!
      restart!
    end

    def converge!(opts = {})
      puts "Converging #{name}".color(:red).bright if config.verbose
      self.class.build_order.each do |(type, name)|
        if type == :file
          Matsuri.log :info, "Checking for required file #{name}"
          next if File.file?(name)
          call_on_failure(type, name) || Matsuri.log(:fatal, "Cannot find required file #{name}")
        end

        resource = dep(type, name).new
        if type == :app && !opts[:reboot]
          puts "Shallow converging app #{name}".color(:red).bright if config.verbose
          resource.converge!
        else
          resource.converge!(opts)
        end
      end
    end

    def call_on_failure(type, name)
      return nil unless hook = self.class.failure_hooks.get(type, name)
      send(hook, type, name)
    end

    # Hooks
    def update!(version, opt={})
      Matsuri.log :fatal, "I don't know how to update #{name}. Define me at in the app config."
    end

    def sh!(opt, args)
      Matsuri.log :fatal, "I don't know how to shell into #{name}. Define me at in the app config."
    end

    def console!(opt, args)
      Matsuri.log :fatal, "I don't know how to get to the console for #{name}. Define me at in the app config."
    end

    def build!(opt={})
      Matsuri.log :fatal, "I don't know how to build #{name}. Define me at in the app config."
    end

    def push!(opt={})
      Matsuri.log :fatal, "I don't know how to push #{name}. Define me at in the app config."
    end

    # Helper functions
    def dep(type, name)
      Matsuri::Registry.fetch_or_load type, name
    end

    def app(name, opt={})
      Matsuri::Registry.app(name).new(opt)
    end
  end
end
