require 'singleton'
require 'map'
require 'active_support/core_ext/string/inflections'

module Matsuri
  class Registry
    include Singleton
    VALID_TYPES = %w(pod replication_controller service).freeze

    def data
      @data ||= Map.new
    end

    class << self
      # Helper to load class definitions
      def load_definition(type, name)
        definition_path = File.join(load_path_for(type), "#{name}.rb")
        fail "Unable to load #{type} #{name} at #{definition_path}" unless File.file?(definition_path)

        eval(File.read(definition_path), TOPLEVEL_BINDING, definition_path)
        _klass = instance.data.get(type, name)
        return _klass if _klass

        fail "Unable to find #{type}/#{name} in #{definition_path}"
      end

      # Helper to generate Kubernetes artifact definitions
      def define(type, name, &blk)
        klass_type = case normalize_and_validate_type(type)
                     when 'pod'                    then Matsuri::Kubernetes::Pod
                     when 'replication_controller' then Matsuri::Kubernetes::ReplicationController
                     when 'service'                then Matsuri::Kubernetes::Service
                     else
                       fail "Cannot find type #{type}"
                     end
        klass = Class.new(klass_type)
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
        return if instance.data.get(type, name)
        load_definition(type, name)
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

      private

      def load_path_for(type)
        case type.to_s
        when 'pod'                    then Matsuri::Config.pods_path
        when 'replication_controller' then Matsuri::Config.rcs_path
        when 'service'                then Matsuri::Config.services_path
        else
          fail ArgumentError, "Unknown Kubernetes type #{type}"
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
        else
          fail ArgumentError, "Unknown Kubernetes type #{type}"
        end
      end

      def maybe_define_module(mod)
        Object.const_set(mod, Module.new) unless Object.const_defined?(mod)
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
