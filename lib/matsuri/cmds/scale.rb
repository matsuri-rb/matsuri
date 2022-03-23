module Matsuri
  module Cmds
    class Scale < Thor
      include Matsuri::Cmd

      def self.scale_cmd_for(resource_name)
        define_method(resource_name) do |name = :not_specified, replicas|
          scale_resource(replicas) { Matsuri::Registry.fetch_or_load(resource_name, name).new }
        end
      end

      desc 'rc RC_NAME REPLICAS', 'scale a replication controller'
      scale_cmd_for :rc

      desc 'replica-set RS_NAME REPLICAS', 'scale a replica set'
      scale_cmd_for :replica_set
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'stateful_set STATEFUL_SET_NAME', 'scale a stateful_set'
      scale_cmd_for :stateful_set
      map sts: :stateful_set

      desc 'deployment DEPLOYMENT_NAME REPLICAS', 'scale a deployment'
      scale_cmd_for :deployment
      map deploy: :deployment

      private

      def scale_resource(replicas)
        with_config do |opt|
          resource = yield
          resource.scale!(replicas, opt)
        end
      end
    end
  end
end
