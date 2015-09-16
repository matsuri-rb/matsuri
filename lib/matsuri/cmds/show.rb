require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmds
    class Show < Thor
      include Matsuri::Cmd

      desc 'config', 'displays config'
      def config
        with_config do |opt|
          puts opt.inspect if opt[:debug]
          puts Matsuri::Config.save(true).deep_stringify_keys.to_yaml
        end
      end

      desc 'pod pod_name', 'show manifest for pod'
      def pod(pod_name)
        with_config do |_|
          puts Matsuri::Registry.pod(pod_name).new.to_yaml
        end
      end

    end
  end
end
