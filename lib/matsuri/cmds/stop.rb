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

    end
  end
end
