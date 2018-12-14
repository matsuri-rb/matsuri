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

        let(:current_namespace) { options[:namespace]  }
        let(:source_file)       { parent_scope[:source_file] }
        let(:skip?)             { options[:skip] }

        let(:parent_scope)      { options[:scoped_options] || {} }

        let(:scoped_options) do
          {
            namespace:   current_namespace,
            source_file: source_file,
            skip:        skip?
          }
        end

        def initialize(options = {}, &block)
          self.definitions = []
          self.options = options
          instance_eval(&block) if block
        end

        # Load and evaluate from a filename.
        # Set the filename and line number so # that errors are correctly reported
        # Inject the relative source path so manifests can be tracked back to a source file
        def self.from_filename(filename, scoped_options = {})
          relative_source = filename.sub(/^#{File.join(Matsuri::Config.base_path, '/')}/, '')
          child_scope = scoped_options.merge(source_file: relative_source)
          new(scoped_options: child_scope).instance_eval(File.read(filename), filename, 1)
        end

        # This could be used by the DSL, but we really should not
        def import(filename)
          definitions << self.class.from_filename(filename, scoped_options)
        end

        ### Manifest sets
        let(:rbac_manifests) { definitions.map(&descend_tree.(:rbac_manifests)) }
        let(:descend_tree)   { ->(m) { ->(x) { x.respond_to?(m) ? x.send(m) : x.map(&m) } } }

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
          final_options = { name: name }.merge(options).merge(scoped_options: scoped_options)
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
          fail ArgumentError, 'cluster_role cannot be invoked inside a namespaced scope' unless current_namespace.nil?

          final_options = { name: name }.merge(options).merge(scoped_options: scoped_options)
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
          fail ArgumentError, 'cluster_role cannot be invoked inside a namespaced scope' unless current_namespace.nil?

          final_options = { name: name }.merge(options).merge(scoped_options: scoped_options)
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
          final_options = { name: name }.merge(options).merge(type: :role, scoped_options: scoped_options)
          fail ArgumentError,
            'bind_role requires namespace to be declared. Either pass namespace as an option or declare it inside ' \
            'a namespace scope.' unless final_options[:namespace].present?

          definitions << Matsuri::DSL::Cluster::Binding.new(final_options, &block)
        end

        def bind_cluster_role(name, options = {}, &block)
          fail ArgumentError, 'bind_cluster_role cannot be invoked inside a namespaced scope' unless current_namespace.nil?
          fail ArgumentError, 'bind_cluster_role cannot be invoked with a namespace' unless options[:namespace].nil?
          final_options = { name: name }.merge(options).merge(type: :cluster_role, scoped_options: scoped_options)

          definitions << Matsuri::DSL::Cluster::Binding.new(final_options, &block)
        end

        # Examples:
        # service_account 'traefik-ingress-controller', namespace: 'kube-system'
        #
        # service_account 'deployer' do
        #   image_pull_secret 'gcp-private-regsitry'
        #
        #   secret 'gcloud-service-account'
        #   secret 'aws-access-token'
        # end
        #
        # service_account 'guest' do
        #   automount_token false
        # end
        def service_account(name, options = {}, &block)
          final_options = { name: name }.merge(options).merge(type: :role, scoped_options: scoped_options)
          require_namespace!('service_account', final_options)

          definitions << Matsuri::DSL::Cluster::ServiceAccount.new(final_options, &block)
        end

        private

        def require_namespace!(helper_name, final_options)
          return if final_options[:namespace].present?

          fail ArgumentError,
            "#{helper_name} requires namespace to be declared. Either pass namespace as an option or declare it inside " \
            'a namespace scope.'
          end
        end
      end
    end
  end
end
