require 'thor'
require 'json'

module Matsuri
  module Initializer
    def self.start(cmd, args)
      # Flush stdout to keep Jenkins updated
      STDOUT.sync = true

      cmd_base = File.basename(cmd)

      # If we symlink a command to the matsuri binary, then we're assuming
      # that the name is the name of the environment. Otherwise, we expect
      # the first argument to be the environment name
      mat_env, final_args = if cmd_base == 'matsuri'
                              [ARGV.first, ARGV[1..-1]]
                            else
                              [cmd_base, args]
                            end

      # Expose matsuri environment to custom initializer
      Matsuri::Config.environment = mat_env
      require Matsuri::Config.initializer_path if File.file?(Matsuri::Config.initializer_path)
      Matsuri::Cmds::Cli.start(final_args)
    end
  end
end
