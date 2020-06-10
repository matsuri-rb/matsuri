module Matsuri
  module Cmds
    class Create < Thor
      include Matsuri::Cmd

      class_option :'no-deps', type: :boolean, default: false

      def self.create_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name|
            create_resource { Matsuri::Registry.fetch_or_load(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name, image_tag = nil|
            create_resource do
              image_tag ||= Matsuri::Registry.fetch_or_load(resource_name, name).new.try(:current_image_tag)
              image_tag ||= 'latest'
              Matsuri::Registry.send(resource_name, name).new(image_tag: image_tag)
            end
          end
        end
      end

      desc 'dns', 'creates cluster dns'
      def dns
        with_config do |_|
          Matsuri::AddOns::DNS.create!
        end
      end

      desc 'pod POD_NAME [IMAGE_TAG]', 'create a pod'
      create_cmd_for :pod, image_tag: true

      desc 'rc RC_NAME [IMAGE_TAG]', 'create a replication controller'
      create_cmd_for :rc, image_tag: true

      desc 'replica-set RS_NAME [IMAGE_TAG]', 'create a replica set'
      create_cmd_for :replica_set, image_tag: true
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'stateful_set STATEFUL_SET_NAME', 'create a stateful_set'
      create_cmd_for :stateful_set, image_tag: true
      map sts: :stateful_set

      desc 'daemon_set DAEMON_SET_NAME', 'create a daemon_set'
      create_cmd_for :daemon_set, image_tag: true
      map ds: :daemon_set

      desc 'deployment DEPLOYMENT_NAME [IMAGE_TAG]', 'create a deployment'
      create_cmd_for :deployment, image_tag: true
      map deploy: :deployment

      desc 'service SERVICE_NAME', 'create a service'
      create_cmd_for :service

      desc 'ingress INGRESS_NAME', 'create a ingress'
      create_cmd_for :ingress

      desc 'endpoints ENDPOINTS_NAME', 'create an endpoint set'
      create_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'upload a secret'
      create_cmd_for :secret

      desc 'config-map CONFIG_MAP_NAME', 'upload a config map'
      create_cmd_for :config_map
      map configmap: :config_map
      map cm: :config_map

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
