module Matsuri
  module Cmds
    class Stop < Thor
      include Matsuri::Cmd

      desc 'pod POD_NAME', 'stop a pod'
      def pod(pod_name)
        with_config do |_|
          Matsuri::Registry.pod(pod_name).new.stop!
        end
      end

    end
  end
end
