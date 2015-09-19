module Matsuri
  module Kubernetes
    class Pod < Matsuri::Kubernetes::Base
      let(:kind) { 'Pod' }

      # Overridables
      let(:spec) do
        {
          containers: containers,
          volumes:    volumes,
        }
      end

      let(:containers) { [container] }
      let(:volumes)    { [volume] }

      let(:container)  { fail NotImplementedError, 'Must define let(:container)'}
      let(:volume)     { fail NotImplementedError, 'Must define let(:volume)' }

      # Helper methods
      def config_file(path)
        File.join config.config_path, path
      end

      def src_path(path)
        File.join config.src_path, path
      end

      def base_path(path)
        File.join config.base_path, path
      end

      # Ruby 2.0+ uses ordered hashes
      def expand_env(hash)
        hash.map { |k,v| { name: k, value: v } }
      end

      def port(num, protocol: 'TCP', name: nil)
        _port = { containerPort: num, protocol: protocol.to_s }
        _port[:name] = name.to_s if name
        return _port
      end

      def mount(name, path)
        { name: name, mountPath: path }
      end

      def host_path_volume(name, host_path)
        { name: name, hostPath: { path: host_path } }
      end

      def empty_dir_volume(name)
        { name: name, emptyDir: {} }
      end
    end
  end
end
