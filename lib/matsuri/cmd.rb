require 'rlet'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmd
    extend Concern

    included do
      private

      def with_config(opts = {})
        _final_options = final_options(opts)

        Matsuri::Config.load_configuration(_final_options)
        Matsuri::Platform.load_configuration(Matsuri::Config.platform_load_paths)

        yield _final_options
      end

      def final_options(opts = {})
        options.merge(parent_options || {}).merge(opts).deep_symbolize_keys
      end
    end
  end
end
