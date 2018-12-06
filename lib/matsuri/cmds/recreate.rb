module Matsuri
  module Cmds
    class Recreate < Thor
      include Matsuri::Cmd

      class_option :r, desc: 'recreate dependencies', type: :boolean, default: false

      def self.recreate_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name|
            recreate_resource { Matsuri::Registry.send(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name, image_tag = nil|
            recreate_resource do
              image_tag ||= Matsuri::Registry.send(resource_name, name).new.try(:current_image_tag)
              image_tag ||= 'latest'
              Matsuri::Registry.send(resource_name, name).new(image_tag: image_tag)
            end
          end
        end
      end

      desc 'pod POD_NAME [IMAGE TAG]', 'recreate a pod'
      recreate_cmd_for :pod, image_tag: true

      desc 'rc RC_NAME [IMAGE TAG]', 'recreate a replication controller'
      recreate_cmd_for :rc, image_tag: true

      desc 'replica-set REPLICA_SET_NAME [IMAGE TAG]', 'recreate a replica set'
      recreate_cmd_for :replica_set, image_tag: true
      map replicaset: :replica_set
      map rs: :replica_set

      desc 'stateful_set STATEFUL_SET_NAME', 'recreate a stateful_set'
      recreate_cmd_for :stateful_set, image_tag: true
      map sts: :stateful_set

      desc 'daemon_set DAEMON_SET_NAME', 'recreate a daemon_set'
      recreate_cmd_for :daemon_set, image_tag: true
      map ds: :daemon_set

      desc 'deployment DEPLOYMENT_NAME [IMAGE TAG]', 'recreate a deployment'
      recreate_cmd_for :deployment, image_tag: true
      map deploy: :deployment

      desc 'service SERVICE_NAME', 'recreate a service'
      recreate_cmd_for :service

      desc 'endpoints ENDPOINTS_NAME', 'recreate an endpoint set'
      recreate_cmd_for :endpoints

      private

      def recreate_resource
        with_config do |opt|
          resource = yield
          resource.recreate!
        end
      end
    end
  end
end
