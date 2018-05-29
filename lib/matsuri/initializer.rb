require 'thor'
require 'json'

module Matsuri
  module Initializer
    def self.start(cmd, args)
      # Flush stdout to keep Jenkins updated
      STDOUT.sync = true

      # Look for the matsuri repo by walking up the parent directories for config/matsuri.rb
      matsuri_base_path = find_matsuri_base(ENV['PWD'])
      Matsuri.log :fatal, 'Unable to find the Matsuri repo. Looking for a config/matsuri.rb file.' unless matsuri_base_path
      Matsuri::Config.base_path = matsuri_base_path

      cmd_base = File.basename(cmd)

      # If we symlink a command to the matsuri binary, then we're assuming
      # that the name is the name of the environment. Otherwise, we expect
      # the first argument to be the environment name
      mat_env, final_args = case
                            when ENV['MATSURI_ENV'].present? && ENV['MATSURI_ENV'] != 'matsuri'
                              [ENV['MATSURI_ENV'], args]
                            when cmd_base == 'matsuri'
                              [ARGV.first, ARGV[1..-1]]
                            else
                              [cmd_base, args]
                            end

      # Expose matsuri environment to custom initializer
      Matsuri::Config.environment = mat_env
      require Matsuri::Config.initializer_path if File.file?(Matsuri::Config.initializer_path)
      Matsuri::Cmds::Cli.start(final_args)
    end

    # Wish we have tail recursion here ...
    def self.find_matsuri_base(cwd)
      return cwd if File.file?(File.join(cwd, 'config/matsuri.rb'))
      find_matsuri_base(File.expand_path('..', cwd)) unless cwd == '/'
    end
  end
end
