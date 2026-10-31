# frozen_string_literal: true

require 'yaml'
require 'matsuri/core_ext'

module Matsuri
  module Cmds
    class Diff < Thor
      include Matsuri::Cmd

      class_option :primary_container, aliases: :p, type: :boolean, default: false
      class_option :hash_diff,         type: :boolean, default: false

      def self.diff_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name = :not_specified|
            diff_resource { Matsuri::Registry.fetch_or_load(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name = :not_specified, image_tag = 'latest'|
            diff_resource { Matsuri::Registry.fetch_or_load(resource_name, name).new(image_tag: image_tag) }
          end
        end
      end

      desc 'stack STACK_NAME', 'diff manifests for all stack members'
      option :stack_config, type: :string, banner: 'PATH'
      def stack(name = :not_specified)
        with_config do |opt|
          Matsuri::Registry.stack(name).new(config: stack_config_data(opt)).diff!(opt)
        end
      end

      desc 'pod POD_NAME', 'diff manifest for pod'
      diff_cmd_for :pod, image_tag: true

      desc 'replica_set REPLICA_SET_NAME', 'diff manifest for replica_set'
      diff_cmd_for :replica_set, image_tag: true
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'stateful_set STATEFUL_SET_NAME', 'diff manifest for stateful_set'
      diff_cmd_for :stateful_set, image_tag: true
      map sts: :stateful_set

      desc 'daemon_set DAEMON_SET_NAME', 'diff manifest for daemon_set'
      diff_cmd_for :daemon_set, image_tag: true
      map ds: :daemon_set

      desc 'deployment DEPLOYMENT_NAME', 'diff manifest for deployment'
      diff_cmd_for :deployment, image_tag: true
      map deploy: :deployment

      desc 'cron-job CRONJOB_NAME', 'apply changes to a cronjob'
      diff_cmd_for :cron_job, image_tag: true
      map cj: :cron_job
      map cronjob: :cron_job

      desc 'service SERVICE_NAME', 'diff manifest for service'
      diff_cmd_for :service

      desc 'ingress INGRESS_NAME', 'diff manifest for ingress'
      diff_cmd_for :ingress

      desc 'endpoints ENDPOINT_NAME', 'diff manifest for endpoints'
      diff_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'diff a secret'
      diff_cmd_for :secret

      desc 'config_map CONFIG_MAP_NAME', 'diff a config map'
      diff_cmd_for :config_map
      map configmap: :config_map
      map cm: :config_map

      desc 'horizontal_pod_autoscaler HPA_NAME', 'diff a horizontal pod autoscaler'
      diff_cmd_for :horizontal_pod_autoscaler
      map hpa: :horizontal_pod_autoscaler

      desc 'pv PV_NAME', 'diff manifest for persistent volume'
      diff_cmd_for :pv

      desc 'pvc PVC_NAME', 'diff manifest for persistent volume claim'
      diff_cmd_for :pvc

      desc 'storage_class STORAGE_CLASS_NAME', 'diff manifest for storage class'
      diff_cmd_for :storage_class

      private

      def diff_resource
        with_config do |opt|
          resource = yield opt
          # --primary-container is a HashDiff-only projection, so it
          # implies --hash-diff
          if opt[:hash_diff] || opt[:primary_container]
            Matsuri::Tasks::HashDiff.new(resource: resource, primary_container: opt[:primary_container]).run!
          else
            Matsuri::Tasks::KubectlOps.diff(resource)
          end
        end
      end
    end
  end
end
