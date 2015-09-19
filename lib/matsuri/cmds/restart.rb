module Matsuri
  module Cmds
    class Restart < Thor
      include Matsuri::Cmd

      class_option :r, desc: 'restart dependencies', type: :boolean, default: false

      desc 'pod POD_NAME', 'restart a pod'
      def pod(name)
        with_config do |opt|
          Matsuri::Registry.pod(name).new.restart!
        end
      end

      desc 'service SERVICE_NAME', 'restart a service'
      def service(name)
        with_config do |opt|
          Matsuri::Registry.service(name).new.restart!
        end
      end

    end
  end
end
