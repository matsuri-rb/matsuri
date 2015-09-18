module Matsuri
  module Cmds
    class K8s < Thor
      include Matsuri::Cmd

      desc 'generate_setup', 'generate setup script for etcd and flanneld'
      def generate_setup
        with_config do |opt|
          Matsuri::Tasks::Kubernetes.new(opt).generate_setup!
        end
      end

      desc 'boot', 'boot up Kubernetes'
      def boot
        with_config do |opt|
          Matsuri::Tasks::Kubernetes.new(opt).up!
        end
      end

      desc 'kill', 'kill Kubernetes'
      def kill
        with_config do |opt|
          Matsuri::Tasks::Kubernetes.new(opt).down!
        end
      end

      desc 'kill_all', 'kill all Docker containers'
      def kill_all
        with_config do |opt|
          Matsuri::Tasks::Docker.new(opt).kill_all!
        end
      end

      desc 'fix_pts', 'fixes pts after booting. sudo required'
      def fix_pts
        with_config do |opt|
          Matsuri::Tasks::Docker.new(opt).fix_pts!
        end
      end

    end
  end
end
