require 'rlet'

module Matsuri
  module Cmd
    extend Concern

    included do
      private

      def with_config(opts = {})
        _final_options = final_options(opts)
        config_file = _final_options[:config]
        Matsuri::Config.from_file(config_file) if File.file?(config_file)
        yield _final_options
      end

      def final_options(opts = {})
        options.merge(parent_options || {}).merge(opts)
      end
    end
  end
end
