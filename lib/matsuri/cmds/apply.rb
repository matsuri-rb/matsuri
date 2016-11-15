require 'active_support/core_ext/object/try'

module Matsuri
  module Cmds
    class Apply < Thor
      include Matsuri::Cmd

      def self.apply_cmd_for(resource_name, image_tag: false)
        unless image_tag
          define_method(resource_name) do |name|
            apply_resource { Matsuri::Registry.send(resource_name, name).new }
          end
        else
          define_method(resource_name) do |name, image_tag = nil|
            apply_resource do
              image_tag ||= Matsuri::Registry.send(resource_name, name).new.try(:current_image_tag)
              image_tag ||= 'latest'
              Matsuri::Registry.send(resource_name, name).new(image_tag: image_tag)
            end
          end
        end
      end

      desc 'pod POD_NAME', 'apply changes to a pod'
      apply_cmd_for :pod, image_tag: true

      desc 'rc RC_NAME', 'apply changes to a rc'
      apply_cmd_for :rc, image_tag: true

      desc 'replica-set REPLICA-SET_NAME', 'apply changes to a replica-set'
      apply_cmd_for :replica_set, image_tag: true

      desc 'deployment DEPLOYMENT_NAME', 'apply changes to a deployment'
      apply_cmd_for :deployment, image_tag: true

      desc 'service SERVICE_NAME', 'apply changes to a service'
      apply_cmd_for :service, image_tag: true

      desc 'secret SECRET_NAME', 'apply changes to a secret'
      apply_cmd_for :secret, image_tag: true

      private

      def apply_resource
        with_config do |opt|
          resource = yield
          resource.apply!
        end
      end
    end
  end
end
