module Matsuri
  module Cmds
    class Status < Thor
      include Matsuri::Cmd

      def self.status_cmd_for(resource_name)
        define_method(resource_name) do |name|
          status_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'app APP_NAME', 'app status'
      status_cmd_for :app

      desc 'pod POD_NAME', 'pod status'
      status_cmd_for :pod

      desc 'rc RC_NAME [IMAGE_TAG]', 'replication controller status'
      status_cmd_for :rc

      desc 'service SERVICE_NAME', 'service status'
      status_cmd_for :service

      desc 'endpoints ENDPOINTS_NAME', 'endpoint set status'
      status_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'secret status'
      status_cmd_for :secret

      desc 'pv PV_NAME', 'persistent volume status'
      status_cmd_for :pv

      desc 'storage_class STORAGE_CLASS_NAME', 'storage class status'
      status_cmd_for :storage_class

      private

      def status_resource
        with_config do |opt|
          resource = yield
          resource.status!
        end
      end

    end
  end
end
