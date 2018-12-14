require 'rlet'
require 'active_support/core_ext/object/blank'

module Matsuri
  module DSL
    module Cluster
      # Non K8S object. This class encapsulates the idea of a scope for the DSL. Currently,
      # the only attribute accepted by the scope is namespace. This is also the
      # entry point for the DSL.
      class Scope
        include Let
        include Matsuri::DSL::Concerns::ManifestSet

        # @TODO see if kubectl reconcile will also handle the general resources
        # If not, we will have to reconcile rbac resources and apply the rest
        attr_accessor :definitions, :options

        let(:namespace) { options[:namespace] }

        def initialize(options = {}, &block)
          self.definitions = []
          self.options = options
          instance_eval(&block) if block
        end

        ### Manifest sets
        let(:rbac_manifests) { definitions.map(&:rbac_manifests) }

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
        #
        #   # Creates a single RoleBinding with the same name as the Role, in the same namespace
        #   # All bind_to are aggregated into subjects for that RoleBinding
        #   bind_to 'deployer', kind: :service_account # namespace defaults to role namespace
        #   bind_to 'deployer', kind: :service_account, namespace: 'qa0'
        #   bind_to 'alice@example.com', kind: :user
        #   bind_to 'sysadmins', kind: :group
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

        # cluster_role 'traefik-ingress-controller' do
        #   # labels 'example.com/addon', 'traefik'
        #   # aggregate_to :admin, :edit
        #   # urls '/api', verbs: :get
        #
        #   resources %w[services endpoints secrets], verbs: %w[get list watch]
        #   resources :ingresses,                     verbs: %w[get list watch], api_groups: :extensions
        #
        #   # Creates a single ClusterRoleBinding with the same name as the ClusterRole
        #   # All bind_to are aggregated into subjects for that ClusterRoleBinding
        #   bind_to 'traefik-ingress-controller', kind: :service_account, namespace: 'kube-system'
        # end
        def cluster_role(name, options = {}, &block)
          fail ArgumentError, 'cluster_role cannot be invoked inside a namespaced scope' unless self.namespace.nil?

          final_options = { name: name }.merge(options).merge(namespace: nil)
          definitions << Matsuri::DSL::Cluster::ClusterRole.new(final_options).tap do |role|
            if options[:resources].present? && options[:verbs].present?
              role.resources(options[:resources], names: options[:resource_names], verbs: options[:verbs], api_groups: options[:api_groups])
            end

            role.configure(&block)
          end
        end

        # Defines a cluster role aggregated from other roles using label selectors
        # Examples:
        # aggregated_cluster_role 'platform-admin' do
        #   # Example using match labels
        #   match 'example.com/aggregate-to-admin' => 'true',
        #         'rails-app' => 'frontend'
        #
        #   # Example using match expressions
        #   match 'legal.io/aggregate-to-admin', :in, 'true'
        #   match 'legal.io/aggregate-to-admin', :in, %w[v1 v2 v3]
        #   match 'legal.io/aggregate-to-admin', :not_in, 'true'
        #   match 'legal.io/aggregate-to-admin', :not_in, 'true'
        #   match 'legal.io/aggregate', :exists
        #   match 'legal.io/aggregate', :does_not_exist
        # end
        def aggregated_cluster_role(name, options = {}, &block)
          fail ArgumentError, 'cluster_role cannot be invoked inside a namespaced scope' unless self.namespace.nil?

          final_options = { name: name }.merge(options).merge(namespace: nil)
          definitions << Matsuri::DSL::Cluster::ClusterRole.new(final_options, &block)
        end

        # Examples
        #  bind :role, 'failover-operator', namespace: :default do
        #    subject 'mongodb-operator', kind: :service_account, namespace: :default
        #    subject 'redis-operator',   kind: :service_account, namespace: :default
        #  end
        #
        # namespace :default do
        #   bind :role, 'failover-operator', do
        #     subject 'mongodb-operator', kind: :service_account, namespace: :default
        #     subject 'redis-operator',   kind: :service_account, namespace: :default
        #   end
        # end
        #
        # bind :cluster_role, 'traefik-ingress-controller' do
        #  subject 'traefik-ingress-controller', kind: :service_account, namespace: 'kube-system'
        # end
        def bind(type, name, options = {}, &block)
          case type
          when :role then bind_role(name, options, &block)
          when :cluster_role then bind_cluster_role(name, options, &block)
          else
            fail ArgumentError, "bind type must be :role or :cluster_role. Is: #{type}"
          end
        end

        def bind_role(name, options = {}, &block)
          final_options = { name: name, namespace: self.namespace }.merge(options).merge(type: :role)
          fail ArgumentError,
            'bind_role requires namespace to be declared. Either pass namespace as an option or declare it inside ' \
            'a namespace scope.' unless final_options[:namespace].present?

          definitions << Matsuri::DSL::Cluster::Binding.new(final_options, &block)
        end

        def bind_cluster_role(name, options = {}, &block)
          fail ArgumentError, 'bind_cluster_role cannot be invoked inside a namespaced scope' unless self.namespace.nil?
          fail ArgumentError, 'bind_cluster_role cannot be invoked with a namespace' unless options[:namespace].nil?
          final_options = { name: name }.merge(options).merge(type: :cluster_role)

          definitions << Matsuri::DSL::Cluster::Binding.new(final_options, &block)
        end
      end
    end
  end
end
