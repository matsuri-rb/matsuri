module Matsuri
  module Cmds
    class Stop < Thor
      include Matsuri::Cmd

      desc 'dns', 'stops cluster dns'
      def dns
        with_config do |_|
          Matsuri::AddOns::DNS.stop!
        end
      end

      desc 'pod POD_NAME', 'stop a pod'
      def pod(name)
        with_config do |_|
          Matsuri::Registry.pod(name).new.stop!
        end
      end

      desc 'rc RC_NAME', 'stop a replication controller'
      def rc(name)
        with_config do |_|
          Matsuri::Registry.rc(name).new.stop!
        end
      end

      desc 'service SERVICE_NAME', 'stop a service'
      def service(name)
        with_config do |_|
          Matsuri::Registry.service(name).new.stop!
        end
      end

      desc 'endpoints ENDPOINTS_NAME', 'stop an endpoint set'
      def endpoints(name)
        with_config do |_|
          Matsuri::Registry.endpoints(name).new.stop!
        end
      end

      desc 'app APP_NAME', 'stops all resources in an app'
      def app(name)
        with_config do |_|
          Matsuri::Registry.app(name).new.stop!
        end
      end

      desc 'secret SECRET_NAME', 'delete a secret'
      def secret(name)
        with_config do |opt|
          Matsuri::Registry.secret(name).new.stop!
        end
      end

      def self.stop_cmd_for(resource_name)
        define_method(resource_name) do |name|
          stop_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'pv PV_NAME', 'stop a persistent volume'
      stop_cmd_for :pv

      private

      def stop_resource
        with_config do |opt|
          resource = yield
          resource.stop!
        end
      end
    end
  end
end
