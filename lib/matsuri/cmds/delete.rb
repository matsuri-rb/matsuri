module Matsuri
  module Cmds
    class Delete < Thor
      include Matsuri::Cmd

      def self.delete_cmd_for(resource_name)
        define_method(resource_name) do |name|
          delete_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'dns', 'deletes cluster dns'
      def dns
        with_config do |_|
          Matsuri::AddOns::DNS.delete!
        end
      end

      desc 'pod POD_NAME', 'delete a pod'
      delete_cmd_for :pod

      desc 'rc RC_NAME', 'delete a replication controller'
      delete_cmd_for :rc

      desc 'replica_set REPLICA_SET_NAME', 'delete a replica_set'
      delete_cmd_for :replica_set
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'stateful_set STATEFUL_SET_NAME', 'delete stateful_set'
      delete_cmd_for :stateful_set
      map sts: :stateful_set

      desc 'daemon_set DAEMON_SET_NAME', 'delete daemon_set'
      delete_cmd_for :daemon_set
      map ds: :daemon_set

      desc 'deployment DEPLOYMENT_NAME', 'delete a deployment'
      delete_cmd_for :deployment
      map deploy: :deployment

      desc 'service SERVICE_NAME', 'delete a service'
      delete_cmd_for :service

      desc 'ingress INGRESS_NAME', 'delete a ingress'
      delete_cmd_for :ingress

      desc 'endpoints ENDPOINTS_NAME', 'delete an endpoint set'
      delete_cmd_for :endpoints

      desc 'app APP_NAME', 'deletes all resources in an app'
      delete_cmd_for :app

      desc 'secret SECRET_NAME', 'delete a secret'
      delete_cmd_for :secret

      desc 'config-map CONFIG_MAP_NAME', 'delete a config map'
      delete_cmd_for :config_map
      map configmap: :config_map
      map cm: :config_map

      desc 'pv PV_NAME', 'delete a persistent volume'
      delete_cmd_for :pv

      desc 'pvc PVC_NAME', 'delete a persistent volume claim'
      delete_cmd_for :pvc

      desc 'storage_class STORAGE_CLASS_NAME', 'delete a storage class'
      delete_cmd_for :storage_class

      private

      def delete_resource
        with_config do |opt|
          resource = yield
          resource.delete!
        end
      end
    end
  end
end
