require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmds
    class Show < Thor
      include Matsuri::Cmd

      class_option :json, aliases: :j, type: :boolean, default: false

      desc 'config', 'displays config'
      def config
        with_config do |opt|
          puts opt.inspect if opt[:debug]
          conf = Matsuri::Config.save(true)
          if options[:json]
            puts JSON.pretty_generate(conf)
          else
            puts conf.deep_stringify_keys.to_yaml
          end
        end
      end

      desc 'pod POD_NAME', 'show manifest for pod'
      def pod(pod_name)
        with_config do |_|
          pod = Matsuri::Registry.pod(pod_name).new
          if options[:json]
            puts pod.pretty_print
          else
            puts pod.to_yaml
          end
        end
      end

    end
  end
end
