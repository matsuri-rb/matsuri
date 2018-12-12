require 'rlet'
require 'active_support/core_ext/object/blank'

module Matsuri
  module Dsl
    class ClusterScope
      include Let

      # @TODO see if kubectl reconcile will also handle the general resources
      # If not, we will have to reconcile rbac resources and apply the rest
      attr_accessor :definitions, :options

      let(:namespace) { options[:namespace] }

      def initialize(options = {}, &block)
        self.definitions = []
        self.options = options
        instance_eval(&block) if block
      end

      ### DSL methods
      def scope(options = {}, &block)
        Matsuri::DSL::ClusterScope.new(options, &block)
      end

      def namespace(name, &block)
        scope(namespace: name, &block)
      end

      # Examples:
      # role 'role-reader', namespace: 'default', api_groups: '', resources: :pods, verbs: %w[get watch list]
      #
      # role 'deployer', namespace: 'default'  do
      #   rule api_groups: '', resources: 'pods',       verbs: %w[get watch list]
      #   rule api_groups: '', resources: 'deployments, verbs: %w[get watch list]
      #
      #   # `resources` are short-hand for the `rule` helper
      #   resources :pods, verbs: %w[get watch list]
      #   resources :pods, verbs: %w[get watch list], names: 'toolbox'
      #   resources :deployments, verbs: %w[patch update], names: %w[legalio-web legalio-resque legalio-resque-algolia]
      # end
      def role(name, options = {}, &block)
        final_options = { name: name, namespace: self.namespace }.merge(options)
        definitions << Matsuri::DSL::Cluster::Role.new(final_options).tap do |role|
          if options[:resources].present? && options[:verbs].present?
            role.resources(options[:resources], names: options[:resource_names], verbs: options[:verbs], api_groups: options[:api_groups])
          end

          role.configure(&block)
        end
      end

      def cluster_role(name, options = {}, &block)
        fail ArgumentError, 'cluster_role cannot be invoked inside a namespaced scope' unless self.namespace.nil?

        final_options = { name: name, namespace: self.namespace }.merge(options).merge(namespace: nil)
        definitions << Matsuri::DSL::Cluster::ClusterRole.new(final_options).tap do |role|
          if options[:resources].present? && options[:verbs].present?
            role.resources(options[:resources], names: options[:resource_names], verbs: options[:verbs], api_groups: options[:api_groups])
          end

          role.configure(&block)
        end
      end

      def aggregated_cluster_role(name, options = {}, &block)
        fail ArgumentError, 'cluster_role cannot be invoked inside a namespaced scope' unless self.namespace.nil?

        final_options = { name: name, namespace: self.namespace }.merge(options).merge(namespace: nil)
        definitions << Matsuri::DSL::Cluster::ClusterRole.new(final_options, &block)
      end
    end
  end
end
