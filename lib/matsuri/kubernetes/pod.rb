module Matsuri
  module Kubernetes
    class Pod < Matsuri::Kubernetes::Base
      let(:kind) { 'Pod' }

      # Overridables
      let(:metadata) { { labels: labels } }
      let(:spec) do
        {
          containers: containers,
          volumes:    volumes
        }
      end

      let(:containers) { [container] }
      let(:volumes)    { [volume] }

      let(:labels)     { { } }
      let(:container)  { fail NotImplementedError, 'Must define let(:container)'}
      let(:volume)     { fail NotImplementedError, 'Must define let(:volume)' }

      # Commands
      def start!
        puts to_json if config.verbose
        shell_out! "kubectl create -f -", input: to_json
      end

      def reload!
        fail NotImplementedError, 'Can only replace image fields, not implemented yet'
        puts to_json if config.verbose
        shell_out! "kubectl replace -f -", input: to_json
      end

      def stop!
        shell_out! "kubectl stop pods/#{name}"
      end

      def rebuild!
        stop!
        start!
      end

      # Helper methods
      def config_file(path)
        File.join config.config_path, path
      end

      def mount(name, path)
        { name: name, mountPath: path }
      end

      def host_path_volume(name, host_path)
        { name: name, hostPath: { path: host_path } }
      end
    end
  end
end
