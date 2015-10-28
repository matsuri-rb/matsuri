module Matsuri
  module Kubernetes
    class Pod < Matsuri::Kubernetes::Base
      let(:kind) { 'Pod' }

      # Overridables
      let(:spec) do
        {
          containers: containers,
          volumes:    volumes,
          imagePullSecrets: image_pull_secrets,
        }
      end

      let(:containers)         { [container] }
      let(:volumes)            { [volume] }
      let(:image_pull_secrets) { [] }
      let(:resources)          { { requests: resource_requests, limits: resource_limits } }
      let(:resource_requests)  { { cpu: cpu_request, memory: mem_request } }
      let(:resource_limits)    { { cpu: cpu_limit,   memory: mem_limit  } }

      let(:container)   { fail NotImplementedError, 'Must define let(:container)'}
      let(:volume)      { fail NotImplementedError, 'Must define let(:volume)' }

      let(:primary_image) { fail NotImplementedError, 'Must defne let(:primary_image) for replication controller' }

      # We want to make sure all limits are defined
      let(:cpu_limit)   { fail NotImplementedError, 'Must define let(:cpu_limit)' }
      let(:mem_limit)   { fail NotImplementedError, 'Must define let(:mem_limit)' }
      let(:cpu_request) { cpu_limit }
      let(:mem_request) { cpu_limit }

      # Helper methods
      def config_file(path)
        File.join config.config_path, path
      end

      def cache_path(path)
        File.join config.cache_path, path
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

      def mount(name, path, read_only: false)
        { name: name, mountPath: path, readOnly: read_only }
      end

      def host_path_volume(name, host_path)
        { name: name, hostPath: { path: host_path } }
      end

      def empty_dir_volume(name)
        { name: name, emptyDir: {} }
      end

      def secret_volume(name, secret_name:)
        { name: name, secret: { secretName: secret_name } }
      end
    end
  end
end
