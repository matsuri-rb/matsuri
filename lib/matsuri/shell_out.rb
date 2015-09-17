require 'mixlib/shellout'

module Matsuri
  module ShellOut
    SHELLOUT_DEFAULTS = { cwd: ENV['PWD'] }

    # Override
    def verbose
      Matsuri::Config.verbose
    end

    def debug
      Matsuri::Config.debug
    end

    def shell_out(_cmd, options = {})
      puts "$ #{_cmd}" if verbose
      options = SHELLOUT_DEFAULTS.merge(timeout: 3600).merge(options)
      cmd = Mixlib::ShellOut.new(_cmd, options)
      cmd.live_stream = STDOUT
      cmd.run_command
      cmd
    end

    def shell_out!(_cmd, options = {})
      cmd = shell_out(_cmd, options)
      return if cmd.status.success?
      $stderr.print "ERROR: #{cmd.exitstatus}\nSTDOUT:\n#{cmd.stdout}\n\nSTDERR:\n#{cmd.stderr}\n"
      exit 1
    end

    def docker(_cmd, options = {})
      shell_out("docker #{_cmd}", options)
    end

    def docker!(_cmd, options = {})
      shell_out!("docker #{_cmd}", options)
    end

    def docker_run(_cmd, options = {})
      docker("run #{_cmd}", options)
    end

    def docker_run!(_cmd, options = {})
      docker!("run #{_cmd}", options)
    end

    def bundle_exec(cmd, options = {})
      shell_out "bundle exec #{cmd}", options
    end

    def bundle_exec!(cmd, options = {})
      shell_out! "bundle exec #{cmd}", options
    end

    def sudo(cmd, options = {})
      shell_out "sudo #{cmd}", options
    end

    def sudo!(cmd, options = {})
      shell_out! "sudo #{cmd}", options
    end
  end
end
