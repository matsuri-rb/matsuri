module Matsuri
  module Tasks
    class Docker
      include Matsuri::Task

      def kill_all!
        docker! 'stop $(docker ps -a -q)'
        docker! 'rm $(docker ps -a -q)'
      end
    end
  end
end
