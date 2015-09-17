module Matsuri
  module Cmds
    class Start < Thor
      include Matsuri::Cmd

      desc 'pod POD_NAME', 'start a pod'
      def pod(pod_name)
        with_config do |_|
          pod = Matsuri::Registry.pod(pod_name).new
          pod.start!
        end
      end

    end
  end
end
