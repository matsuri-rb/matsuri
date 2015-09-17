module Matsuri
  module Cmds
    class Reload < Thor
      include Matsuri::Cmd

      desc 'pod POD_NAME', 'reload a pod'
      def pod(pod_name)
        with_config do |_|
          Matsuri::Registry.pod(pod_name).new.reload!
        end
      end

    end
  end
end
