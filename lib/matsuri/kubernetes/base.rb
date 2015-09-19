require 'rlet'
require 'json'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'rainbow/ext/string'

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

      let(:final_metadata)   { default_metadata.merge(metadata) }
      let(:default_metadata) { { name: name, namespace: namespace, labels: labels } }
      let(:namespace)        { 'default' }
      let(:resource_type)    { kind.to_s.downcase }
      let(:labels)           { { } }

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
        puts "Starting #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        shell_out! "kubectl --namespace=#{namespace} create -f -", input: to_json
      end

      def stop!
        puts "Stopping #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        shell_out! "kubectl --namespace=#{namespace} delete #{resource_type}/#{name}"
      end

      def reload!
        fail NotImplementedError, 'Must implement #reload!'
        puts to_json if config.verbose
        shell_out! "kubectl replace -f -", input: to_json
      end

      def restart!
        stop!
        start!
      end

      def converge!(opts = {})
        puts "Converging #{resource_type}/#{name}".color(:yellow) if config.verbose
        puts "Rebuild not implemented. Restarting instead.".color(:red).bright if opts[:rebuild]

        if opts[:restart] || opts[:rebuild]
          if started?
            restart!
          else
            start!
          end
        else
          start! unless started?
        end

      end

      # Helper functions
      def started?
        cmd = shell_out "kubectl --namespace=#{namespace} get #{resource_type}/#{name}", no_stdout: true
        return cmd.status.success? unless config.verbose

        status = if cmd.status.success?
                   "already started"
                 else
                   "not started"
                 end
        puts "#{resource_type}/#{name} #{status}".color(:yellow)
        cmd.status.success?
      end

      def config
        Matsuri::Config
      end

      def pod(name)
        Matsuri::Registry.pod(name).new
      end

      def replication_controller(name)
        Matsuri::Registry.replication_controller(name).new
      end

      alias_method :rc, :replication_controller

      def service(name)
        Matsuri::Registry.service(name).new
      end

      def endpoints(name)
        Matsuri::Registry.endpoints(name).new
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
