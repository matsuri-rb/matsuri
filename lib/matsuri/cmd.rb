# frozen_string_literal: true

require 'map'
require 'rlet'
require 'yaml'
require 'matsuri/core_ext'

module Matsuri
  module Cmd
    extend Concern

    included do
      private

      def with_config(opts = {})
        _final_options = final_options(opts)

        Matsuri::Config.apply_configuration(_final_options)

        yield _final_options
      end

      def final_options(opts = {})
        options.merge(parent_options || {}).merge(opts).deep_symbolize_keys
      end

      # The CLI owns the boundary mapping; the built-in ImageTag acceptor
      # owns the default — the same single owner the stack :image_tag
      # collection uses. The positional may be nil.
      def image_tag_for(positional)
        Matsuri::Acceptors::ImageTag.new(positional).image_tag
      end

      # The CLI owns the boundary mapping: --stack-config= names a path,
      # the stack's :config collection expects data. No flag is the empty
      # value; a flag with a bad path fails loudly, never falls back.
      def stack_config_data(opt)
        path = opt[:stack_config]
        return nil unless path

        Matsuri.log(:fatal, "stack-config not found: #{path}") unless File.file?(path)
        Map.new(YAML.safe_load_file(path, aliases: true))
      end
    end
  end
end
