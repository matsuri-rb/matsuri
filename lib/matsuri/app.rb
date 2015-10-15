require 'map'
require 'active_support/core_ext/class/attribute'
require 'rainbow/ext/string'

module Matsuri
  class App
    include Let
    include Matsuri::ShellOut

    class_attribute :build_order

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
      def needs(type, name)
        self.build_order ||= []
        self.build_order << [type.to_sym, name.to_s]
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
        resource = dep(type, name).new
        if type == :app && !opts[:reboot]
          puts "Shallow converging app #{name}".color(:red).bright if config.verbose
          resource.converge!
        else
          resource.converge!(opts)
        end
      end
    end

    # Hooks
    def console!(opt, args)
      Matsuri.log :fatal, "I don't know how to shell into #{name}. Define me at in the app config."
    end

    # Helper functions
    def config
      Matsuri::Config
    end

    def dep(type, name)
      Matsuri::Registry.fetch_or_load type, name
    end

    def pod(name)
      Matsuri::Registry.pod(name).new
    end

    def replication_controller(name)
      Matsuri::Registry.replication_controller(name).new
    end

    alias_method :rc, :replication_controller

    def service(name)
      Matsuri::Registry.service(name).new
    end

    def endpoints(name)
      Matsuri::Registry.endpoints(name).new
    end

    def app(name)
      Matsuri::Registry.app(name).new
    end
  end
end
