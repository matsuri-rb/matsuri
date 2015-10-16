require 'singleton'
require 'map'
require 'active_support/core_ext/string/inflections'

module Matsuri
  class Registry
    include Singleton
    VALID_TYPES = %w(pod replication_controller service endpoints secret app).freeze

    def data
      @data ||= Map.new
    end

    class << self
      # Helper to load class definitions
      def load_definition(type, name)
        def_path = definition_path(type, name)

        eval(File.read(def_path), TOPLEVEL_BINDING, def_path)
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

        resource = instance.data.get(_type, name)
        return resource if resource

        load_definition(_type, name)
      end

      def pod(name)
        fetch_or_load :pod, name
      end

      def service(name)
        fetch_or_load :service, name
      end

      def replication_controller(name)
        fetch_or_load :replication_controller, name
      end

      def rc(name)
        replication_controller(name)
      end

      def endpoints(name)
        fetch_or_load :endpoints, name
      end

      def secret(name)
        fetch_or_load :secret, name
      end

      def app(name)
        fetch_or_load :app, name
      end

      private

      def parent_class(type, parent_name)
        return fetch_or_load(type, parent_name) if parent_name
        case normalize_and_validate_type(type)
        when 'pod'                    then Matsuri::Kubernetes::Pod
        when 'replication_controller' then Matsuri::Kubernetes::ReplicationController
        when 'service'                then Matsuri::Kubernetes::Service
        when 'endpoints'              then Matsuri::Kubernetes::Endpoints
        when 'secret'                 then Matsuri::Kubernetes::Secret
        when 'app'                    then Matsuri::App
        else
          fail "Cannot find type #{type}"
        end
      end

      def load_path_for(type)
        case type.to_s
        when 'pod'                    then Matsuri::Config.pods_path
        when 'replication_controller' then Matsuri::Config.rcs_path
        when 'service'                then Matsuri::Config.services_path
        when 'endpoints'              then Matsuri::Config.endpoints_path
        when 'secret'                then Matsuri::Config.secrets_path
        when 'app'                    then Matsuri::Config.apps_path
        else
          fail ArgumentError, "Unknown Matsuri type #{type}"
        end
      end

      def class_name_for(name)
        name.to_s.gsub(/-/, '_').camelize
      end

      def module_for(type)
        case type.to_s
        when 'pod'                    then maybe_define_module('Pods')
        when 'replication_controller' then maybe_define_module('ReplicationControllers')
        when 'service'                then maybe_define_module('Services')
        when 'endpoints'              then maybe_define_module('Endpoints')
        when 'secret'                then maybe_define_module('Secrets')
        when 'app'                    then maybe_define_module('Apps')
        else
          fail ArgumentError, "Unknown Matsuri type #{type}"
        end
      end

      def maybe_define_module(mod)
        return Object.const_get(mod) if Object.const_defined?(mod)
        Object.const_set(mod, Module.new)
      end

      def normalize_and_validate_type(type)
        _type = type.to_s.freeze
        _type = 'replication_controller' if _type == 'rc'
        return _type if VALID_TYPES.include?(_type)

        fail "Registery type #{type.inspect} invalid. Use one of #{VALID_TYPES}" unless VALID_TYPES.include?(type)
      end
    end
  end
end
