module Matsuri
  module Cmds
    class Create < Thor
      include Matsuri::Cmd

      class_option :'no-deps', type: :boolean, default: false

      def self.create_cmd_for(resource_name)
        define_method(resource_name) do |name|
          create_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'dns', 'creates cluster dns'
      def dns
        with_config do |_|
          Matsuri::AddOns::DNS.create!
        end
      end

      desc 'pod POD_NAME [IMAGE_TAG]', 'create a pod'
      def pod(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.pod(name).new(image_tag: image_tag).create!
        end
      end

      desc 'rc RC_NAME [IMAGE_TAG]', 'create a replication controller'
      def rc(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.rc(name).new(image_tag: image_tag).create!
        end
      end

      desc 'replica-set RS_NAME [IMAGE_TAG]', 'create a replica set'
      def replica_set(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.replica_set(name).new(image_tag: image_tag).create!
        end
      end
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'deployment DEPLOYMENT_NAME [IMAGE_TAG]', 'create a deployment'
      def deployment(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.deployment(name).new(image_tag: image_tag).create!
        end
      end
      map deploy: :deployment

      desc 'service SERVICE_NAME', 'create a service'
      create_cmd_for :service

      desc 'endpoints ENDPOINTS_NAME', 'create an endpoint set'
      create_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'upload a secret'
      create_cmd_for :secret

      desc 'pv PV_NAME', 'create a persistent volume'
      create_cmd_for :pv

      desc 'pvc PVC_NAME', 'create a persistent volume claim'
      create_cmd_for :pvc

      desc 'storage_class STORAGE_CLASS_NAME', 'upload a storage class'
      create_cmd_for :storage_class

      private

      def create_resource
        with_config do |opt|
          resource = yield
          resource.create!
        end
      end
    end
  end
end
