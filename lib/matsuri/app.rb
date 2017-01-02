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
    include Matsuri::Concerns::Awaiting

    class_attribute :build_order

    # When we pass image_tag to converge command, propogate this
    # down the convergance tree.
    let(:image_tag) { options[:image_tag] }

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
    #
    # Hooks:
    #   check_only: when set to true, do not create or apply resource. Only check for it's presence
    #   on_failure: a symbol of a method to call when check fails.
    #
    # @TODO Consider making this lazy-loaded. We don't need to generate this elaborate data structure
    # unless we are converging. (But it might not really make things that much slower).
    class << self
      def needs(type, name, on_failure: nil, check_only: false)
        self.build_order ||= []
        self.build_order << [type.to_sym, name.to_s, { on_failure: on_failure, check_only: check_only }]
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

    # Override this. This commands defines how to display the status
    # Maybe we can find some useful, standardized way of displaying
    # status.
    def status!
      fail NotImplementedError, 'Must implement #status!'
    end

    # Override this. This command defines how all the app depenencies
    # are started, such as services, endpoints, replication controllers, etc.
    def create!
      converge! # Most of the time, we want to converge
    end

    # Override this. This command defines how all app dependencies are stopped
    def delete!
      self.class.build_order.each do |(type, name)|
        if type == :app
          puts "Skipping app #{name}"
          next
        end

        dep(type, name).new.delete!
      end
    end

    def recreate!
      delete!
      create!
    end

    def rebuild!
      build!
      recreate!
    end

    def converge!(opts = {})
      puts "Converging #{name}".color(:red).bright if config.verbose
      self.class.build_order.each do |(type, name, options)|
        if type == :file
          Matsuri.log :info, "Checking for required file #{name}"
          next if File.file?(name)
          Matsuri.log(:fatal, "Cannot find required file #{name}") unless options[:on_failure]
          send(options[:on_failure], type, name)
        end

        resource = dep(type, name).new(image_tag: image_tag)
        # @TODO if-elsif-end ladder code smell, refactor
        if options[:check_only]
          next if resource.created?
          send(options[:on_failure], type, name) || Matsuri.log(:fatal, "#{type}/#{name} not found on cluster")
        elsif type == :app && !opts[:reboot]
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

    class << self
      def load_path
        Matsuri::Config.apps_path
      end

      def definition_module_name
        'Apps'
      end
    end
  end
end
