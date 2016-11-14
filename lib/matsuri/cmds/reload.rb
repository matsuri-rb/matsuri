module Matsuri
  module Cmds
    class Reload < Thor
      include Matsuri::Cmd

      def self.reload_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name|
            reload_resource { Matsuri::Registry.send(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name, image_tag = 'latest'|
            reload_resource { Matsuri::Registry.send(resource_name, name).new(image_tag: image_tag) }
          end
        end
      end

      desc 'pod POD_NAME', 'reload a pod'
      reload_cmd_for :pod, image_tag: true

      desc 'rc RC_NAME', 'reload a rc'
      reload_cmd_for :rc, image_tag: true

      desc 'replica-set REPLICA-SET_NAME', 'reload a replica-set'
      reload_cmd_for :replica_set, image_tag: true

      desc 'deployment DEPLOYMENT_NAME', 'reload a deployment'
      reload_cmd_for :deployment, image_tag: true

      desc 'service SERVICE_NAME', 'reload a service'
      reload_cmd_for :service, image_tag: true

      desc 'secret SECRET_NAME', 'reload a secret'
      reload_cmd_for :secret, image_tag: true

      private

      def reload_resource
        with_config do |opt|
          resource = yield
          resource.reload!
        end
      end
    end
  end
end
