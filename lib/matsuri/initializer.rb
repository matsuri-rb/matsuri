require 'thor'
require 'json'

module Matsuri
  module Initializer
    def self.call
      # Flush stdout to keep Jenkins updated
      STDOUT.sync = true

      require Matsuri::Config.initializer_path if File.file?(Matsuri::Config.initializer_path)
    end
  end
end
