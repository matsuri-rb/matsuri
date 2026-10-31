# frozen_string_literal: true

require 'rlet'

require 'matsuri/core_ext'

require 'rainbow/ext/string'
require 'rlet/lazy_options'

module Matsuri
  module Kubernetes
    class Base
      include Let
      include RLet::LazyOptions
      include Matsuri::Concerns::ExportManifest
      include Matsuri::Concerns::RegistryHelpers
      include Matsuri::Concerns::Diffable

      # Namespace resolution
      let(:namespace)             { namespace_from_option || default_namespace }

      # Override default namespace instead of namespace in order to override namespace
      # from the command line
      let(:default_namespace)     { namespace_from_config || 'default' }
      let(:namespace_from_option) { options[:namespace] }
      let(:namespace_from_config) { env_config.namespace }
      let(:env_config)            { Matsuri::Platform.send(Matsuri.environment) }

      # Kubernetes manifest
      let(:manifest) do
        {
          apiVersion:  api_version,
          kind:        kind,
          metadata:    final_metadata,
          spec:        spec
        }
      end

      let(:final_metadata)      { default_metadata.merge(metadata) }
      let(:default_metadata)    { { name: name, namespace: namespace, labels: final_labels, annotations: final_annotations } }
      # Needed for autodetecting 'current' for rolling-updates. However, this is obsolete with Deployments
      let(:default_labels)      { { 'matsuri-name' => name, 'matsuri-env' => matsuri_env, 'namespace' => namespace } }
      let(:default_annotations) { { } }
      let(:final_labels)        { default_labels.merge(labels) }
      let(:final_annotations)   { default_annotations.merge(annotations) }
      let(:resource_type)       { kind.to_s.downcase }
      let(:labels)              { { } }
      let(:annotations)         { { } }
      let(:matsuri_env)         { Matsuri.environment }

      # Optional parameters
      # The acceptor instance the owning stack bound for this converge; nil
      # when the definition is invoked standalone.
      let(:stack_config) { options[:stack_config] }

      # Delivery policy, read by the Tasks::KubectlOps boundary. Resources
      # declare what delivery should do; the mechanism lives in the tasks.
      let(:converge_via) { :apply }
      let(:apply_via)    { :apply }
      let(:save_config)  { true }

      # Diff policy, read by Tasks::HashDiff. The path to the primary
      # container within the manifest; resources with a pod template
      # declare it so the focused diff (--primary-container) can project
      # both manifests to the same container.
      let(:primary_container_path) { nil }

      # Overridables
      let(:spec)        { fail NotImplementedError, 'Must define let(:spec)' }

      # Helper functions
      # Conditionally returns block or nil
      # Useful for conditionally adding evironmental variables or list of volumes
      # Example:
      #   let(:use_keyfile?) { false }
      #   let(:volumes)      { [maybe(use_keyfile?) { mongo-keyfile-volume }].compact }
      def maybe(cond)
        yield if cond
      end
    end
  end
end
