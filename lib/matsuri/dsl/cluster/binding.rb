require 'rlet'
require 'active_support/core_ext/hash/compact'

module Matsuri
  module DSL
    module Cluster
      # This DSL covers both RoleBinding and ClusterRoleBinding
      # Defaults:
      #   - binding_type determines default for role_ref.kind unless overridden
      #   - role ref name defaults to the name of this binding
      #   - role ref kind defaults to equivalent kind for this binding
      #   - role ref api_group defaults to rbac.authorization.kubernetes.io
      #   - subject namespace defaults to namespace for this binding
      #   - subject api_group defaults to rbac.authorization.kubernetes.io for User and Group
      #   - subject api_group defaults to "" (core) for other kinds (ServiceAccounts)
      class Binding
        include Let
        include Matsuri::Concerns::ExportManifest
        include Matsuri::DSL::Concerns::Metadata
        include Matsuri::DSL::Concerns::ManifestSet

        attr_accessor :role_ref, :subjects

        ### Parameters
        let(:binding_type)   { options[:type] }

        ### Manifest Set
        let(:rbac_manifests) { subjects.any? && manifest } # Return manifest only if there are subjects defined for binding

        ### Manifest
        let(:api_version)    { Matsuri::Config.rbac_api_version }
        let(:final_role_ref) { role_ref || default_role_ref }
        let(:manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    metadata,
            roleRef:     final_role_ref,
            subjects:    subjects
          }
        end

        let(:kind) do
          case binding_type
          when :role, 'Role', 'role'                        then 'RoleBinding'
          when :cluster_role, 'ClusterRole', 'cluster_role' then 'ClusterRoleBinding'
          else
            fail ArgumentError, "binding_type must be one of :role or :cluster_role, is: #{binding_type.inspect}"
          end
        end

        let(:default_role_ref)           { { kind: default_role_ref_kind, name: default_role_ref_name, apiGroup: default_role_ref_api_group } }
        let(:default_role_ref_name)      { name }
        let(:default_role_ref_api_group) { 'rbac.authorization.k8s.io' }
        let(:default_role_ref_kind)      { map_binding_type_to_kind(binding_type) }

        def initialize(options = {}, &block)
          initialize_metadata_dsl(options)
          self.subjects = []

          configure(&block) if block
        end

        def configure(&block)
          instance_eval(&block)
        end

        ### DSL Helpers
        def reference(type, name = default_role_ref_name, api_group: default_role_ref_api_group)
          self.role_ref = {
            kind:     map_binding_type_to_kind(type),
            name:     name,
            apiGroup: api_group
          }
        end

        def subject(name, kind:, namespace: nil, api_group: nil)
          self.subjects << {
            name:      name,
            kind:      map_subject_type_to_kind(kind),
            namespace: namespace,
            api_group: api_group || default_subject_api_group(kind)
          }.compact
        end

        ### Helpers
        def map_binding_type_to_kind(type)
          case type
          when :role, 'Role', 'role'                        then 'Role'
          when :cluster_role, 'ClusterRole', 'cluster_role' then 'ClusterRole'
          else
            fail ArgumentError, "binding type must be one of :role or :cluster_role, is: #{type.inspect}"
          end
        end

        def map_subject_type_to_kind(type)
          case type
          when :user then 'User'
          when :group then 'Group'
          when :service_account then 'ServiceAccount'
          else
            fail ArgumentError, "subject type must be one of :user, :group, :service_account, is: #{type.inspect}"
          end
        end

        def default_subject_api_group(type)
          case type
          when :user, :group then 'rbac.authorization.k8s.io'
          when :service_account then ''
          else
            fail ArgumentError, "subject type must be one of :user, :group, :service_account, is: #{type.inspect}"
          end
        end
      end
    end
  end
end
