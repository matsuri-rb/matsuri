require 'active_support/concern'

module Matsuri
  module Concerns
    # This module contains helpers to make it easy to reference things
    # around the Matsuri platforms. For example, you can reference other pods,
    # rcs, or reference configuration settings.
    module RegistryHelpers
      extend ActiveSupport::Concern

      included do
        def config
          Matsuri::Config
        end

        def pod(name, opt={})
          Matsuri::Registry.pod(name).new(opt)
        end

        def replication_controller(name, opt={})
          Matsuri::Registry.replication_controller(name).new(opt)
        end

        alias_method :rc, :replication_controller

        def service(name, opt={})
          Matsuri::Registry.service(name).new(opt)
        end

        def endpoints(name, opt={})
          Matsuri::Registry.endpoints(name).new(opt)
        end
      end
    end
  end
end
