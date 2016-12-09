require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmds
    class Diff < Thor
      include Matsuri::Cmd

      class_option :json, aliases: :j, type: :boolean, default: false

      def self.diff_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name|
            diff_resource { Matsuri::Registry.send(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name, image_tag = 'latest'|
            diff_resource { Matsuri::Registry.send(resource_name, name).new(image_tag: image_tag) }
          end
        end
      end

      desc 'pod POD_NAME', 'diff manifest for pod'
      diff_cmd_for :pod, image_tag: true

      desc 'rc RC_NAME', 'diff manifest for rc'
      diff_cmd_for :rc, image_tag: true

      desc 'replica_set REPLICA_SET_NAME', 'diff manifest for replica_set'
      diff_cmd_for :replica_set, image_tag: true
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'deployment DEPLOYMENT_NAME', 'diff manifest for deployment'
      diff_cmd_for :deployment, image_tag: true
      map deploy: :deployment

      desc 'service SERVICE_NAME', 'diff manifest for service'
      diff_cmd_for :service

      desc 'endpoints ENDPOINT_NAME', 'diff manifest for endpoints'
      diff_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'diff a secret'
      diff_cmd_for :secret

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
          resource.diff!
        end
      end
    end
  end
end
