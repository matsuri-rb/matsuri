module Matsuri
  module Cmds
    class Stop < Thor
      include Matsuri::Cmd

      def self.stop_cmd_for(resource_name)
        define_method(resource_name) do |name|
          stop_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'dns', 'stops cluster dns'
      def dns
        with_config do |_|
          Matsuri::AddOns::DNS.stop!
        end
      end

      desc 'pod POD_NAME', 'stop a pod'
      stop_cmd_for :pod

      desc 'rc RC_NAME', 'stop a replication controller'
      stop_cmd_for :rc

      desc 'replica_set REPLICA_SET_NAME', 'stop a replica_set'
      stop_cmd_for :replica_set

      desc 'deployment DEPLOYMENT_NAME', 'stop a deployment'
      stop_cmd_for :deployment

      desc 'service SERVICE_NAME', 'stop a service'
      stop_cmd_for :service

      desc 'endpoints ENDPOINTS_NAME', 'stop an endpoint set'
      stop_cmd_for :endpoints

      desc 'app APP_NAME', 'stops all resources in an app'
      stop_cmd_for :app

      desc 'secret SECRET_NAME', 'delete a secret'
      stop_cmd_for :secret

      desc 'pv PV_NAME', 'stop a persistent volume'
      stop_cmd_for :pv

      desc 'pvc PVC_NAME', 'stop a persistent volume claim'
      stop_cmd_for :pvc

      desc 'storage_class STORAGE_CLASS_NAME', 'delete a storage class'
      stop_cmd_for :storage_class

      private

      def stop_resource
        with_config do |opt|
          resource = yield
          resource.stop!
        end
      end
    end
  end
end
