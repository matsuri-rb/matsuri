# frozen_string_literal: true

require 'thor'
require 'json'

module Matsuri
  module Initializer
    def self.start(args)
      # Flush stdout to keep CI harnesses updated
      STDOUT.sync = true

      # Look for the matsuri repo by walking up the parent directories for
      # config/matsuri.rb. ENV['PWD'] preserves the path as the shell
      # presented it; non-shell execs may not set it, hence the fallback.
      matsuri_base_path = find_matsuri_base(ENV['PWD'] || Dir.pwd)
      Matsuri.log :fatal, 'Unable to find the Matsuri repo. Looking for a config/matsuri.rb file.' unless matsuri_base_path
      Matsuri::Config.base_path = matsuri_base_path

      # The repo contributes code through matsuri, not through its launcher;
      # every repo-authored file from here on may assume lib/ is loadable.
      # See docs/design/boot.md
      $LOAD_PATH.unshift(Matsuri::Config.lib_path) if File.directory?(Matsuri::Config.lib_path)

      # The environment has exactly one source: the first positional
      # argument (see docs/design/boot.md). Set before loading configuration
      # so config files and the custom initializer can read it.
      Matsuri::Config.environment = args.first
      Matsuri::Config.load_configuration(Matsuri::Config.repo_defaults_path)
      Matsuri::Platform.load_configuration(Matsuri::Config.platform_load_paths)

      require Matsuri::Config.initializer_path if File.file?(Matsuri::Config.initializer_path)
      Matsuri::Cmds::Cli.start(args.drop(1))
    end

    # Wish we have tail recursion here ...
    def self.find_matsuri_base(cwd)
      return cwd if File.file?(File.join(cwd, 'config/matsuri.rb'))
      find_matsuri_base(File.expand_path('..', cwd)) unless cwd == '/'
    end
  end
end
