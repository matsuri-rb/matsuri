module Matsuri
  module Cmds
    class Start < Thor
      include Matsuri::Cmd

      class_option :'no-deps', type: :boolean, default: false

      desc 'pod POD_NAME', 'start a pod'
      def pod(name)
        with_config do |opt|
          Matsuri::Registry.pod(name).new.start!
        end
      end

      desc 'service SERVICE_NAME', 'start a service'
      def service(name)
        with_config do |opt|
          Matsuri::Registry.service(name).new.start!
        end
      end

    end
  end
end
