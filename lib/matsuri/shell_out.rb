require 'mixlib/shellout'
require 'rainbow/ext/string'

module Matsuri
  module ShellOut
    module_function

    SHELLOUT_DEFAULTS = { cwd: ENV['PWD'] }

    # Override
    def verbose
      Matsuri::Config.verbose
    end

    def debug
      Matsuri::Config.debug
    end

    # Overridable
    # By default, the environment name is used. However, if you are using
    # something like GCP, it is easier to set this in config/platform.rb
    # and pull it from there. To override this, use let() or just define
    # a method. For example, put this in a Staging mixin:
    # let(:kube_context) { platform.staging.kube_context }
    def kube_context
      if Matsuri::Config.map_env_to_kube_context
        Matsuri::Platform.send(Matsuri::Config.environment).kube_context
      else
        Matsuri::Config.environment
      end
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
      $stderr.print "ERROR: #{cmd.exitstatus}\nSTDOUT:\n#{cmd.stdout}\n\nSTDERR:\n#{cmd.stderr}\n".color(:red).bright
      exit 1
    end

    # This is so that it is easier to write app commands
    def kubectl_cmd(_cmd)
      "kubectl --context=#{kube_context} #{_cmd}"
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
