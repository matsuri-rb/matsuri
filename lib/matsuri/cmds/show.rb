require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmds
    class Show < Thor
      include Matsuri::Cmd

      class_option :json, aliases: :j, type: :boolean, default: false

      def self.show_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name|
            show_resource { Matsuri::Registry.send(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name, image_tag = 'latest'|
            show_resource { Matsuri::Registry.send(resource_name, name).new(image_tag: image_tag) }
          end
        end
      end

      desc 'config', 'displays config'
      def config
        with_config do |opt|
          puts opt.inspect if opt[:debug]
          conf = Matsuri::Config.save(true)
          platform = Matsuri::Platform.save(true)
          if options[:json]
            puts JSON.pretty_generate(conf), JSON.pretty_generate(platform)
          else
            puts conf.deep_stringify_keys.to_yaml, platform.deep_stringify_keys.to_yaml
          end
        end
      end

      desc 'dns', 'displays DNS Add On definition'
      def dns
        with_config do |opt|
          Matsuri::AddOns::DNS.show!(opt)
        end
      end

      desc 'pod POD_NAME', 'show manifest for pod'
      show_cmd_for :pod, image_tag: true

      desc 'rc RC_NAME', 'show manifest for rc'
      show_cmd_for :rc, image_tag: true

      desc 'replica_set REPLICA_SET_NAME', 'show manifest for replica_set'
      show_cmd_for :replica_set, image_tag: true
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'stateful_set STATEFUL_SET_NAME', 'show manifest for stateful_set'
      show_cmd_for :stateful_set, image_tag: true
      map sts: :stateful_set

      desc 'daemon_set DAEMON_SET_NAME', 'show manifest for daemon_set'
      show_cmd_for :daemon_set, image_tag: true
      map ds: :daemon_set

      desc 'deployment DEPLOYMENT_NAME', 'show manifest for deployment'
      show_cmd_for :deployment, image_tag: true
      map deploy: :deployment

      desc 'service SERVICE_NAME', 'show manifest for service'
      show_cmd_for :service

      desc 'ingress INGRESS_NAME', 'show manifest for ingress'
      show_cmd_for :ingress

      desc 'endpoints ENDPOINT_NAME', 'show manifest for endpoints'
      show_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'show a secret'
      show_cmd_for :secret

      desc 'config-map CONFIG_MAP_NAME', 'show a config map'
      map configmap: :config_map
      show_cmd_for :config_map

      desc 'pv PV_NAME', 'show manifest for persistent volume'
      show_cmd_for :pv

      desc 'pvc PVC_NAME', 'show manifest for persistent volume claim'
      show_cmd_for :pvc

      desc 'storage_class STORAGE_CLASS_NAME', 'show manifest for storage class'
      show_cmd_for :storage_class

      desc 'cluster', 'show manifest set for cluster-wide manifests (RBAC, ResourceQuota, NetworkPolicy, etc.)'
      def cluster
        with_config { |opt| Matsuri::Tasks::Cluster.new.show!(opt) }
      end

      private

      def show_resource
        with_config do |opt|
          resource = yield opt
          if options[:json]
            puts resource.pretty_print
          else
            puts resource.to_yaml
          end
        end
      end
    end
  end
end
