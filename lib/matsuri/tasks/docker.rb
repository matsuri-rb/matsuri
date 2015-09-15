module Matsuri
  module Tasks
    class Docker
      include Matsuri::Task

      def kill_all!
        docker! 'stop $(docker ps -a -q)'
        docker! 'rm $(docker ps -a -q)'
      end

      def fix_pts!
        puts 'sudo mount -o remount,ptmxmode=666 /dev/pts'
      end
    end
  end
end
