module Matsuri
  module Cmds
    class K8s < Thor
      desc 'boot', 'boot up Kubernetes'
      def boot
        Matsuri::Tasks::Kubernetes.new(final_options).up!
      end

      desc 'kill', 'kill Kubernetes'
      def kill
        Matsuri::Tasks::Kubernetes.new(final_options).down!
      end

      desc 'kill_all', 'kill all Docker containers'
      def kill_all
        Matsuri::Tasks::Docker.new(final_options).kill_all!
      end

      private
      def final_options
        options.merge(parent_options)
      end
    end
  end
end
