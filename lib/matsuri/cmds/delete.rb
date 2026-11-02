# frozen_string_literal: true

module Matsuri
  module Cmds
    class Delete < Thor
      include Matsuri::Cmd

      def self.delete_cmd_for(resource_name)
        define_method(resource_name) do |name = :not_specified|
          delete_resource { Matsuri::Registry.fetch_or_load(resource_name, name).new }
        end
      end

      desc 'pod POD_NAME', 'delete a pod'
      delete_cmd_for :pod

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

      desc 'cron-job CRONJOB_NAME', 'apply changes to a cronjob'
      delete_cmd_for :cron_job
      map cj: :cron_job
      map cronjob: :cron_job

      desc 'service SERVICE_NAME', 'delete a service'
      delete_cmd_for :service

      desc 'ingress INGRESS_NAME', 'delete a ingress'
      delete_cmd_for :ingress

      desc 'endpoints ENDPOINTS_NAME', 'delete an endpoint set'
      delete_cmd_for :endpoints

      desc 'stack STACK_NAME', 'deletes all resources in a stack'
      def stack(name = :not_specified)
        with_config do |opt|
          Matsuri::Registry.fetch_or_load(:stack, name).new.delete!
        end
      end

      desc 'secret SECRET_NAME', 'delete a secret'
      delete_cmd_for :secret

      desc 'config-map CONFIG_MAP_NAME', 'delete a config map'
      delete_cmd_for :config_map
      map configmap: :config_map
      map cm: :config_map

      desc 'horizontal_pod_autoscaler HPA_NAME', 'delete a horizontal pod autoscaler'
      delete_cmd_for :horizontal_pod_autoscaler
      map hpa: :horizontal_pod_autoscaler

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
          Matsuri::Tasks::KubectlOps.delete(resource)
        end
      end
    end
  end
end
