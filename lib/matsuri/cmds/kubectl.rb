module Matsuri
  module Cmds
    class Kubectl < Thor
      include Matsuri::Cmd

      desc 'setup', 'generate aliases for kubectl context'
      def setup
        with_config do |opt|
          Matsuri::Tasks::Kubectl.new(opt).setup!
        end
      end
    end
  end
end
