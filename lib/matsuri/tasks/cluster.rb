require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Tasks
    # Converge cluster
    class Cluster
      include Matsuri::Task

      let(:root_scope)             { Matsuri::DSL::Cluster::Scope.new(namespace: nil) }

      let(:all_files)              { global_files + environment_files }
      let(:global_files)           { Dir.glob(File.join(clusters_path, Matsuri.environment, '**', '*.rb')) }
      let(:environment_files)      { Dir.glob(File.join(clusters_path, '*.rb')) }
      let(:clusters_path)          { Matsuri::Config.clusters_path }

      let(:all_rbac_manifests)            { load_all! && root_scope.rbac_manifests.flatten.compact }
      let(:rbac_manifests_to_yaml)        { all_rbac_manifests.map(&:deep_stringify_keys).map(&:to_yaml) }
      let(:rbac_manifests_to_json)        { all_rbac_manifests.map(&:to_json) }
      let(:rbac_manifests_to_pretty_json) { all_rbac_manifests.map(&JSON.method(:pretty_generate)) }

      # Memoized so it only evaluates once
      let(:load_all!)              { all_files.each(&method(:load_definition!)) }

      def load_definition!(filename)
        root_scope.import(filename)
      end

      def reconcile!(opt = {})
        puts 'Converging cluster-wide configuration'.color(:yellow) if config.verbose
        reconcile_rbac!(opt)
      end

      def reconcile_rbac!(_opt)
        Matsuri.log :info, 'Reconciling RBAC'

        # kubectl_options = opt[:dry_run] ? '--dry-run' : ''

        kubectl! "auth reconcile -f -", input: rbac_manifests_to_json.join("\n")
      end
    end
  end
end
