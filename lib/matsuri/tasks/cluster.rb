require 'yaml'

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

      let(:all_rbac_manifests)     { load_all! && root_scope.rbac_manifests.flatten.compact }
      let(:rbac_manifests_to_yaml) { all_rbac_manifests.map(&:to_yaml) }

      # Memoized so it only evaluates once
      let(:load_all!)              { all_files.each(&method(:load_definition!)) }

      def load_definition!(filename)
        root_scope.import(filename)
      end
    end
  end
end
