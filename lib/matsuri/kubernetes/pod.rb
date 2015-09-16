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
