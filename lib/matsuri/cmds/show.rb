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

      desc 'dns', 'displays DNS Add On definition'
      def dns
        with_config do |opt|
          Matsuri::AddOns::DNS.show!(opt)
        end
      end

      desc 'pod POD_NAME', 'show manifest for pod'
      def pod(name)
        with_config do |_|
          pod = Matsuri::Registry.pod(name).new
          if options[:json]
            puts pod.pretty_print
          else
            puts pod.to_yaml
          end
        end
      end

      desc 'rc RC_NAME', 'show manifest for replication controller'
      def rc(name)
        with_config do |_|
          rc = Matsuri::Registry.rc(name).new
          if options[:json]
            puts rc.pretty_print
          else
            puts rc.to_yaml
          end
        end
      end

      desc 'service SERVICE_NAME', 'show manifest for service'
      def service(name)
        with_config do |_|
          service = Matsuri::Registry.service(name).new
          if options[:json]
            puts service.pretty_print
          else
            puts service.to_yaml
          end
        end
      end

      desc 'endpoints ENDPOINT_NAME', 'show manifest for endpoints'
      def endpoints(name)
        with_config do |_|
          endpoints = Matsuri::Registry.endpoints(name).new
          if options[:json]
            puts endpoints.pretty_print
          else
            puts endpoints.to_yaml
          end
        end
      end

      desc 'secret SECRET_NAME', 'show a secret'
      def secret(name)
        with_config do |opt|
          secret = Matsuri::Registry.secret(name).new
          if options[:json]
            puts secret.pretty_print
          else
            puts secret.to_yaml
          end
        end
      end

    end
  end
end
