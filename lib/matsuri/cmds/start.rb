module Matsuri
  module Cmds
    class Start < Thor
      include Matsuri::Cmd

      class_option :'no-deps', type: :boolean, default: false

      def self.start_cmd_for(resource_name)
        define_method(resource_name) do |name|
          start_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'dns', 'starts cluster dns'
      def dns
        with_config do |_|
          Matsuri::AddOns::DNS.start!
        end
      end

      desc 'pod POD_NAME [IMAGE_TAG]', 'start a pod'
      def pod(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.pod(name).new(image_tag: image_tag).start!
        end
      end

      desc 'rc RC_NAME [IMAGE_TAG]', 'start a replication controller'
      def rc(name, image_tag = 'latest')
        with_config do |opt|
          Matsuri::Registry.rc(name).new(image_tag: image_tag).start!
        end
      end

      desc 'service SERVICE_NAME', 'start a service'
      start_cmd_for :service

      desc 'endpoints ENDPOINTS_NAME', 'start an endpoint set'
      start_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'upload a secret'
      start_cmd_for :secret

      desc 'pv PV_NAME', 'start a persistent volume'
      start_cmd_for :pv

      desc 'storage_class STORAGE_CLASS_NAME', 'upload a storage class'
      start_cmd_for :storage_class

      private

      def start_resource
        with_config do |opt|
          resource = yield
          resource.start!
        end
      end
    end
  end
end
