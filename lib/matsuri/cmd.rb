require 'rlet'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmd
    extend Concern

    included do
      private

      def with_config(opts = {})
        _final_options = final_options(opts)
        config_file = _final_options[:config]
        Matsuri::Config.from_file(config_file) if File.file?(config_file)
        Matsuri::Config.verbose = _final_options[:verbose] if _final_options[:verbose]
        Matsuri::Config.debug   = _final_options[:debug]   if _final_options[:debug]

        yield _final_options
      end

      def final_options(opts = {})
        options.merge(parent_options || {}).merge(opts).deep_symbolize_keys
      end
    end
  end
end
