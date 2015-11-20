module Matsuri
  module Cmds
    class Status < Thor
      include Matsuri::Cmd

      desc 'app APP_NAME', 'app status'
      def pod(name)
        with_config do |opt|
          Matsuri::Registry.pod(name).new.status!
        end
      end

      desc 'pod POD_NAME', 'pod status'
      def pod(name)
        with_config do |opt|
          Matsuri::Registry.pod(name).status!
        end
      end

      desc 'rc RC_NAME [IMAGE_TAG]', 'replication controller status'
      def rc(name)
        with_config do |opt|
          Matsuri::Registry.rc(name).new.status!
        end
      end

      desc 'service SERVICE_NAME', 'service status'
      def service(name)
        with_config do |opt|
          Matsuri::Registry.service(name).new.status!
        end
      end

      desc 'endpoints ENDPOINTS_NAME', 'endpoint set status'
      def endpoints(name)
        with_config do |opt|
          Matsuri::Registry.endpoints(name).new.status!
        end
      end

      desc 'secret SECRET_NAME', 'secret status'
      def secret(name)
        with_config do |opt|
          Matsuri::Registry.secret(name).new.status!
        end
      end
    end
  end
end
