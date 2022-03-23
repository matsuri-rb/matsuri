require 'singleton'
require 'map'
require 'active_support/core_ext/string/inflections'

module Matsuri
  class Registry
    include Singleton

    def data
      @data ||= Map.new
    end

    def k8s_class_registry
      @k8s_class_registry ||= Map.new
    end

    def k8s_class_aliases
      @k8s_class_aliases ||= Map.new
    end

    class << self
      # Registers a K8S class, which can then be used for definitions
      def register_class(name, opt = {})
        fail ArgumentError, 'need to pass class: parameter' unless opt[:class]
        instance.k8s_class_registry[name] = opt[:class]
        Array(opt[:aliases]).each do |class_alias|
          instance.k8s_class_aliases[class_alias] = name
        end
      end

      # Helper to load class definitions
      def load_definition(type, name)
        def_path = definition_path(type, name)

        # [Hosh] Somehow, TOPLEVEL_BINDING got infected with version and str
        # local variables. When thinking about it, we probably want to require
        # instead of evaluating this with the TOPLEVEL_BINDING anyways.

        #eval(File.read(def_path), TOPLEVEL_BINDING, def_path)
        require def_path

        _klass = instance.data.get(type, name)
        return _klass if _klass

        Matsuri.log :fatal, "Unable to find #{type}/#{name} defined in #{def_path}"
      end

      def definition_path(type, name)
        load_path    = load_path_for(type)
        def_file     = "#{name}.rb"
        env_def_path = File.join(load_path, Matsuri.environment, def_file)
        return env_def_path if File.file?(env_def_path)
        Matsuri.log :debug, "Unable to find #{env_def_path} ... trying global definition"

        def_path = File.join(load_path, def_file)
        return def_path if File.file?(def_path)
        Matsuri.log :fatal, "Unable to find #{env_def_path} or #{def_path}"
      end

      # Helper to generate Kubernetes artifact definitions
      def define(type, name, inherits: nil, &blk)
        type = normalize_and_validate_type(type)
        parent_klass = parent_class(type, inherits)
        klass = Class.new(parent_klass)
        module_for(type).const_set(class_name_for(name), klass)
        klass.class_eval do
          let(:name) { name }
        end

        klass.class_eval(&blk) if blk

        # TODO: consider whether to use the class or to go ahead
        # and instantiate it
        instance.data.set(type, name, klass)
        return klass
      end

      def register(type, name, obj)
        _type = normalize_and_validate_type(type)
        instance.data.set(_type, name, obj)
      end

      def fetch_or_load(type, name)
        _type = normalize_and_validate_type(type)

        if name == :not_specified
          print_options_for_type(_type)
        end

        resource = instance.data.get(_type, name)
        return resource if resource

        load_definition(_type, name)
      end

      def print_options_for_type(type)
        global_load_path = load_path_for(type)
        env_def_path     = File.join(global_load_path, Matsuri.environment)

        definition_files = Dir.glob(File.join(env_def_path, "*.rb")) + Dir.glob(File.join(global_load_path, "*.rb"))
        if definition_files.empty?
          Matsuri.log :fatal, "Unable to find any definition files in #{env_def_path}"
        end

        Matsuri.log :error, "Which #{type}?\n\n"
        definition_files
          .map  {|file| File.basename(file, File.extname(file))}
          .uniq
          .sort
          .each {|def_name| Matsuri.log :error, "   #{def_name}"}

        Matsuri.log :fatal, "\nPlease specify a #{type} from the above list."
      end

      def pod(name)
        fetch_or_load :pod, name
      end

      def service(name)
        fetch_or_load :service, name
      end

      def ingress(name)
        fetch_or_load :ingress, name
      end

      def replication_controller(name)
        fetch_or_load :replication_controller, name
      end

      def rc(name)
        replication_controller(name)
      end

      def replica_set(name)
        fetch_or_load :replica_set, name
      end

      def stateful_set(name)
        fetch_or_load :stateful_set, name
      end

      def daemon_set(name)
        fetch_or_load :daemon_set, name
      end

      def deployment(name)
        fetch_or_load :deployment, name
      end

      def persistent_volume(name)
        fetch_or_load :persistent_volume, name
      end

      def pv(name)
        persistent_volume(name)
      end

      def persistent_volume_claim(name)
        fetch_or_load :persistent_volume_claim, name
      end

      def pvc(name)
        persistent_volume_claim(name)
      end

      def storage_class(name)
        fetch_or_load :storage_class, name
      end

      def endpoints(name)
        fetch_or_load :endpoints, name
      end

      def secret(name)
        fetch_or_load :secret, name
      end

      def config_map(name)
        fetch_or_load :config_map, name
      end

      def horizontal_pod_autoscaler(name)
        fetch_or_load :horizontal_pod_autoscaler, name
      end

      def hpa(name)
        horizontal_pod_autoscaler(name)
      end

      def app(name)
        fetch_or_load :app, name
      end

      private

      def parent_class(type, parent_name = nil)
        return fetch_or_load(type, parent_name) if parent_name
        instance.k8s_class_registry[normalize_and_validate_type(type)]
      end

      def load_path_for(type)
        parent_class(type).load_path
      end

      def class_name_for(name)
        name.to_s.gsub(/-/, '_').camelize
      end

      def module_for(type)
        maybe_define_module(parent_class(type).definition_module_name)
      end

      def maybe_define_module(mod)
        return Object.const_get(mod) if Object.const_defined?(mod)
        Object.const_set(mod, Module.new)
      end

      def normalize_and_validate_type(type)
        _type = type.to_s.freeze
        _type = instance.k8s_class_aliases[_type] if instance.k8s_class_aliases.key?(_type)
        return _type if instance.k8s_class_registry.key?(_type)

        fail "Registery type #{type.inspect} invalid. Use one of #{instance.k8s_class_registry.keys}"
      end
    end
  end
end

# Register the definition classes
# TODO: Consider making this dynamically and lazy loaded
Matsuri::Registry.register_class 'app',                       class: Matsuri::App
Matsuri::Registry.register_class 'pod',                       class: Matsuri::Kubernetes::Pod
Matsuri::Registry.register_class 'replication_controller',    class: Matsuri::Kubernetes::ReplicationController, aliases: %w[rc]
Matsuri::Registry.register_class 'service',                   class: Matsuri::Kubernetes::Service
Matsuri::Registry.register_class 'ingress',                   class: Matsuri::Kubernetes::Ingress
Matsuri::Registry.register_class 'endpoints',                 class: Matsuri::Kubernetes::Endpoints
Matsuri::Registry.register_class 'secret',                    class: Matsuri::Kubernetes::Secret
Matsuri::Registry.register_class 'config_map',                class: Matsuri::Kubernetes::ConfigMap
Matsuri::Registry.register_class 'replica_set',               class: Matsuri::Kubernetes::ReplicaSet,            aliases: %w[rs]
Matsuri::Registry.register_class 'stateful_set',              class: Matsuri::Kubernetes::StatefulSet,           aliases: %w[sts]
Matsuri::Registry.register_class 'daemon_set',                class: Matsuri::Kubernetes::DaemonSet,             aliases: %w[ds]
Matsuri::Registry.register_class 'deployment',                class: Matsuri::Kubernetes::Deployment
Matsuri::Registry.register_class 'persistent_volume',         class: Matsuri::Kubernetes::PersistentVolume, aliases: %w[pv]
Matsuri::Registry.register_class 'persistent_volume_claim',   class: Matsuri::Kubernetes::PersistentVolumeClaim, aliases: %w[pvc]
Matsuri::Registry.register_class 'storage_class',             class: Matsuri::Kubernetes::StorageClass
Matsuri::Registry.register_class 'horizontal_pod_autoscaler', class: Matsuri::Kubernetes::HorizontalPodAutoscaler, aliases: %w[hpa]
