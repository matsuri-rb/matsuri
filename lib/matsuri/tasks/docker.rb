# frozen_string_literal: true

module Matsuri
  module Tasks
    class Docker
      include Matsuri::Task

      # The delivery surface stack hooks delegate to: the hook declares,
      # this task shells out. (ShellOut's own docker! is private on
      # includers — module_function.)
      def run!(cmd, options = {})
        docker!(cmd, options)
      end

      def kill_all!
        docker! 'stop $(docker ps -a -q)'
        docker! 'rm -f $(docker ps -a -q)'
      end

      def fix_pts!
        puts 'sudo mount -o remount,ptmxmode=666 /dev/pts'
      end
    end
  end
end
