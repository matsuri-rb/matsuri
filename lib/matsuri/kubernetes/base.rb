require 'rlet'
require 'json'
require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Kubernetes
    class Base
      include Let
      include Matsuri::ShellOut

      # Kubernetes manifest
      let(:manifest) do
        {
          apiVersion:  api_version,
          kind:        kind,
          metadata:    final_metadata,
          spec:        spec
        }
      end

      let(:final_metadata)    { default_metadata.merge(metadata) }
      let(:default_metadata)  { { name: name } }

      # Overridables
      let(:api_version) { 'v1' }
      let(:kind)        { fail NotImplementedError, 'Must define let(:kind)' }
      let(:metadata)    { { } }
      let(:name)        { fail NotImplementedError, 'Must define let(:name)' }
      let(:spec)        { fail NotImplementedError, 'Must define let(:spec)' }

      def build!
        fail NotImplementedError, 'Must implement #build!'
      end

      def start!
        fail NotImplementedError, 'Must implement #start!'
      end

      def stop!
        fail NotImplementedError, 'Must implement #stop!'
      end

      def reload!
        fail NotImplementedError, 'Must implement #reload!'
      end

      # Helper functions
      def config
        Matsuri::Config
      end

      def pod(name)
        Matsuri::Registry.pod(name)
      end

      def replication_controller(name)
        Matsuri::Registry.replication_controller(name)
      end

      alias_method :rc, :replication_controller

      def service(name)
        Matsuri::Registry.service(name)
      end

      # Transform functions
      def to_json
        manifest.to_json
      end

      def to_yaml
        manifest.deep_stringify_keys.to_yaml
      end

      def pretty_print
        JSON.pretty_generate(manifest)
      end
    end
  end
end
