require 'rlet'

require 'hashdiff'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'

require 'rainbow/ext/string'
require 'rlet/lazy_options'

module Matsuri
  module Kubernetes
    class Base
      include Let
      include RLet::LazyOptions
      include Matsuri::ShellOut
      include Matsuri::Concerns::TransformManifest
      include Matsuri::Concerns::RegistryHelpers
      include Matsuri::Concerns::Awaiting

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
      let(:release)     { (options[:release] || '0').to_s }

      # Overridables
      let(:spec)        { fail NotImplementedError, 'Must define let(:spec)' }

      def build!
        fail NotImplementedError, 'Must implement #build!'
      end

      def create!
        puts "Creating #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        kubectl! "create --save-config=true --record=true -f -", input: to_json
      end

      def delete!
        puts "Deleting #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        kubectl! "delete #{resource_type}/#{name}"
      end

      def apply!
        puts "Applying (create or update) #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        kubectl! "apply --record=true -f -", input: applied_to_json
      end

      def replace!
        puts "Replacing (create or update) #{resource_type}/#{name}".color(:yellow).bright if config.verbose
        puts to_json if config.debug
        kubectl! "replace --record=true -f -", input: to_json
      end

      def recreate!
        if created?
          # Preload any lazy upstream variable assignments
          to_json

          delete!
          awaiting!('resource deletion', interval: 0.5) { !created? }
        end

        create!
      end

      def status!
        Matsuri.log :fatal, "I don't know how to display a status for #{resource_type}"
      end

      def annotate!(hash = {})
        json = JSON.generate( { metadata: { annotations: hash } } )
        Matsuri.log :info, "Annotating #{resource_type}/#{name} with #{hash.inspect}"
        kubectl! "patch #{resource_type} #{name} -p '#{json}'"
      end

      def converge!(opts = {})
        converge_by_apply!(opts)
      end

      def converge_by_apply!(opts)
        puts "Converging #{resource_type}/#{name} via apply".color(:yellow) if config.verbose
        puts "Rebuild not implemented. Applying instead.".color(:red).bright if opts[:rebuild]
        apply!
      end

      def converge_by_recreate!(opts = {})
        puts "Converging #{resource_type}/#{name} via recreate".color(:yellow) if config.verbose
        puts "Rebuild not implemented. Recreating instead.".color(:red).bright if opts[:rebuild]

        if opts[:restart] || opts[:rebuild]
          if created?
            recreate!
          else
            create!
          end
        else
          create! unless created?
        end
      end

      def diff!(_opt = {})
        print_diff(diff)
      end

      # Helper functions
      # Conditionally returns block or nil
      # Useful for conditionally adding evironmental variables or list of volumes
      # Example:
      #   let(:use_keyfile?) { false }
      #   let(:volumes)      { [maybe(use_keyfile?) { mongo-keyfile-volume }].compact }
      def maybe(cond)
        yield if cond
      end

      def current_manifest(raw: false)
        cmd = kubectl "get #{resource_type}/#{name} -o json", echo_level: :debug, no_stdout: true
        return nil unless cmd.status.success?
        r = JSON.parse(cmd.stdout)
        raw ? r : Map.new(r)
      end

      def diff
        current = current_manifest(raw: true)
        Matsuri.log :fatal, "Cannot fetch current manifest for #{resource_type}/#{name}" unless current

        desired = JSON.parse(to_json)

        # Filter what is being compared
        current.delete('status')
        current['metadata'] = current['metadata'].slice('name', 'labels', 'namespace') if current['metadata']

        HashDiff.diff current, desired
      end

      def print_diff(deltas)
        deltas.each do |line|
          color = case line[0]
                  when '-' then :red
                  when '+' then :green
                  when '~' then :yellow
                  end
          puts line.join(' ').color(color).bright
        end
      end

      def created?
        cmd = kubectl "get #{resource_type}/#{name}", echo_level: :debug, no_stdout: true
        return cmd.status.success? unless config.verbose

        status = if cmd.status.success?
                   "already started"
                 else
                   "not started"
                 end
        Matsuri.log :info, "#{resource_type}/#{name} #{status}".color(:yellow)
        cmd.status.success?
      end
    end
  end
end
