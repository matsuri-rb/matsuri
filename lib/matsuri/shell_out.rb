require 'mixlib/shellout'
require 'rainbow/ext/string'

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

    def kube_environment
      Matsuri::Config.environment
    end

    def shell_out(_cmd, options = {})
      echo_level = options.delete(:echo_level) || :info
      no_stdout = options.delete(:no_stdout)

      Matsuri.log echo_level, "$ #{_cmd}".color(:green)
      options = SHELLOUT_DEFAULTS.merge(timeout: 3600).merge(options)
      cmd = Mixlib::ShellOut.new(_cmd, options)
      cmd.live_stream = STDOUT unless no_stdout && !debug
      cmd.run_command
      cmd
    end

    def shell_out!(_cmd, options = {})
      cmd = shell_out(_cmd, options)
      return cmd if cmd.status.success?
      $stderr.print "ERROR: #{cmd.exitstatus}\nSTDOUT:\n#{cmd.stdout}\n\nSTDERR:\n#{cmd.stderr}\n".red.bright
      exit 1
    end

    # This is so that it is easier to write app commands
    def kubectl_cmd(_cmd)
      "kubectl --context=#{kube_environment} #{_cmd}"
    end

    def kubectl(_cmd, options = {})
      shell_out(kubectl_cmd(_cmd), options)
    end

    def kubectl!(_cmd, options = {})
      shell_out!(kubectl_cmd(_cmd), options)
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
