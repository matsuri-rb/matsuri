# frozen_string_literal: true

require 'map'
require 'matsuri/core_ext'
require 'matsuri/acceptors/image_tag'
require 'rainbow/ext/string'
require 'rlet'
require 'rlet/lazy_options'

module Matsuri
  class Stack
    include Let
    include RLet::LazyOptions
    include Matsuri::ShellOut
    include Matsuri::Concerns::RegistryHelpers
    include Matsuri::Concerns::Awaiting

    class_attribute :build_order
    class_attribute :acceptors

    # The collection name is the options key: each acceptor admits its own
    # component of the invocation options, whole. The built-in :image_tag
    # collection carries the converge positional and owns the 'latest'
    # default; :config carries the stack-config artifact, already loaded —
    # whoever constructs the stack supplies data, never a path.
    let(:image_tag)    { accepted(:image_tag).image_tag }
    let(:stack_config) { accepted(:config) }

    # Defines a list of deps, used to  to idempotently converge Kubernetes
    # resources. Generally, you will add a stack as a dep for resources you are
    # sharing with other stacks, while directly referencing Kubernetes resources
    # for things this stack is directly responsible for.
    #
    # Examples:
    # needs :stack,   'postgresql-95'
    # needs :stack,   'redis-28'
    # needs :stack,      'load-balancer'
    # needs :deployment, 'rails-app-worker'
    # needs :deployment, 'rails-app'
    # needs :service,    'rails-app'
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

      # Registers an acceptor under a named collection. Last declaration
      # per collection wins; a stack overrides a built-in by re-declaring it.
      def accept(collection, acceptor)
        self.acceptors = (acceptors || {}).merge(collection.to_sym => acceptor)
      end
    end

    accept :image_tag, Matsuri::Acceptors::ImageTag
    # Empty acceptor: the collection is total, its surface is empty until
    # a platform re-declares it.
    accept :config, Matsuri::Acceptor

    # Override this. This commands defines how to display the status
    # Maybe we can find some useful, standardized way of displaying
    # status.
    def status!
      fail NotImplementedError, 'Must implement #status!'
    end

    # Renders every member manifest as one kubectl-compatible YAML stream.
    def show!(_opt = {})
      members.each { |member| puts member.to_yaml }
    end

    def diff!(opt = {})
      members.each { |member| member.diff!(opt) }
    end

    # Override this. This command defines how all the stack depenencies
    # are started, such as services, endpoints, replication controllers, etc.
    def create!
      converge! # Most of the time, we want to converge
    end

    # Override this. This command defines how all stack dependencies are stopped
    def delete!
      self.class.build_order.each do |(type, name)|
        if type == :stack
          puts "Skipping stack #{name}"
          next
        end

        # Same options as converge, so a member whose identity derives from
        # an accepted value addresses the same resource it created.
        Matsuri::Tasks::KubectlOps.delete(dep(type, name).new(dep_options(type)))
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
        case type
        when :file
          Matsuri.log :info, "Checking for required file #{name}"
          next if File.file?(name)
          Matsuri.log(:fatal, "Cannot find required file #{name}") unless options[:on_failure]
          send(options[:on_failure], type, name) if options[:on_failure]
        when :task
          Matsuri.log :info, "Executing task #{name}"
          send(name, opts)
          next
        end

        resource = dep(type, name).new(dep_options(type))
        # @TODO if-elsif-end ladder code smell, refactor
        if options[:check_only]
          next if resource.created?
          send(options[:on_failure], type, name) || Matsuri.log(:fatal, "#{type}/#{name} not found on cluster")
        elsif type == :stack && !opts[:reboot]
          puts "Shallow converging stack #{name}".color(:red).bright if config.verbose
          resource.converge!
        elsif type == :stack
          resource.converge!(opts)
        else
          Matsuri::Tasks::KubectlOps.converge(resource, opts)
        end
      end
    end

    # Hooks
    def reload!(version, opt={})
      Matsuri.log :fatal, "I don't know how to reload #{name}. Define me in the stack definition."
    end

    def update!(version, opt={})
      Matsuri.log :fatal, "I don't know how to update #{name}. Define me in the stack definition."
    end

    def sh!(opt, args)
      Matsuri.log :fatal, "I don't know how to shell into #{name}. Define me in the stack definition."
    end

    def console!(opt, args)
      Matsuri.log :fatal, "I don't know how to get to the console for #{name}. Define me in the stack definition."
    end

    # To build this out beyond definition-supplied docker! calls, add a
    # Tasks::Build carrying the mechanism — same shape as
    # Tasks::KubectlOps: the hook declares, the task delivers.
    def build!(opt={})
      Matsuri.log :fatal, "I don't know how to build #{name}. Define me in the stack definition."
    end

    def push!(opt={})
      Matsuri.log :fatal, "I don't know how to push #{name}. Define me in the stack definition."
    end

    # Helper functions
    # stack-config never crosses a stack boundary: instance identity is the
    # (stack, stack-config) pair, and a nested stack is a different instance.
    def dep_options(type)
      return { image_tag: image_tag } if type == :stack

      { image_tag: image_tag, stack_config: stack_config }
    end

    def members
      self.class.build_order.filter_map do |(type, name, _)|
        next if type == :file || type == :task

        if type == :stack
          puts "Skipping stack #{name}"
          next
        end

        dep(type, name).new(dep_options(type))
      end
    end

    def accepted(collection)
      @accepted ||= {}
      @accepted[collection] ||= acceptor_class_for(self.class.acceptors.fetch(collection)).new(options[collection])
    end

    def acceptor_class_for(name)
      name.is_a?(Class) ? name : Matsuri::Registry.acceptor(name)
    end

    def dep(type, name)
      Matsuri::Registry.fetch_or_load type, name
    end

    def stack(name, opt={})
      Matsuri::Registry.stack(name).new(opt)
    end

    class << self
      def load_path
        Matsuri::Config.stacks_path
      end

      def definition_module_name
        'Stacks'
      end
    end
  end
end
