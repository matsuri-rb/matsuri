
require 'mixlib/config'
require 'pathname'

module Matsuri
  # Matsuri-specific configuration. These are things you probably
  # do not want to change. User-defined configs are found in Matsuri::Platform
  # TODO: Move K8S configs out to Platform
  module Config
    extend Mixlib::Config
    config_strict_mode true  # will see how annoying this is

    # Base path of the platform repo, defaults to PWD
    default :base_path, ENV['PWD']
    default :verbose, false
    default :debug, false
    default :environment, 'dev'

    # If set to true, then Matsuri env names will be
    # mapped to kube_context via Matsuri::Platform.
    # By default, Matsuri assumes that the name of the environment
    # is the name of the kubectl context. However, if you are using
    # this with GKE, it is easier to let gcloud handle setting up
    # authentication, in which case we want to map environment names
    # to kubectl context
    # Example: staging -> Matsuri::Platform.staging.kube_context
    # With "staging", you must define Magsuri::Platform.staging.kube_context
    # to pull the correct kube context.
    default :map_env_to_kube_context, false

    # Container Image Versions
    default :etcd_version,      nil # 2.0.12
    default :hyperkube_version, nil # v1.0.1
    default :kube2dns_version,  nil # 1.11
    default :skydns_version,    nil # 2015-03-11-001

    # Networking
    default :dev_addr,         '127.0.0.1' # Replace with local ip
    default :kubernetes_cidr,  '10.1.0.0/16'
    default :etcd_addr,        '127.0.0.1:4001'
    default :etcd_bind_addr,   '0.0.0.0:4001'
    default :master_addr,      '127.0.0.1'
    default :master_bind_addr, '0.0.0.0'
    default :api_servers,      'http://localhost:8080'
    default :master_url,       'http://127.0.0.1:8080'
    default :cluster_dns,      '10.0.0.10'
    default :cluster_domain,   'dev.local'

    # Platform paths
    default(:config_path)           { File.join base_path, 'config' }
    default(:config_secrets_path)   { File.join config_path, 'secrets' } # Actual secrets themselves, should not be versioned
    default(:platform_load_paths)   { [ File.join(config_path, 'platform.rb'), File.join(base_path, '.platform.rb') ] }

    default(:cache_path)                    { File.join base_path, '.cache' }
    default(:build_path)                    { File.join base_path, 'build' }
    default(:docker_path)                   { File.join base_path, 'docker' }
    default(:src_path)                      { File.join base_path, 'src' }
    default(:lib_path)                      { File.join base_path, 'lib' }
    default(:platform_path)                 { File.join base_path, 'platform' }
    default(:images_path)                   { File.join platform_path, 'images' }
    default(:pods_path)                     { File.join platform_path, 'pods' }
    default(:rcs_path)                      { File.join platform_path, 'replication_controllers' }
    default(:persistent_volumes_path)       { File.join platform_path, 'persistent_volumes' }
    default(:persistent_volume_claims_path) { File.join platform_path, 'persistent_volume_claims' }
    default(:storage_classes_path)          { File.join platform_path, 'storage_classes' }
    default(:services_path)                 { File.join platform_path, 'services' }
    default(:endpoints_path)                { File.join platform_path, 'endpoints' }
    default(:apps_path)                     { File.join platform_path, 'apps' }
    default(:secrets_path)                  { File.join platform_path, 'secrets' } # Kubernetes Secret definition, not the actual secrets

    default :manifests_path, '/etc/kubernetes/manifests'

    # Helpers
    def self.host_osx?
      /darwin/ =~ RUBY_PLATFORM
    end

    def self.load_configuration(options = {})
      config_file = options[:config]
      Matsuri::Config.from_file(config_file) if File.file?(config_file)
      Matsuri::Config.verbose     = options[:verbose]     if options[:verbose]
      Matsuri::Config.debug       = options[:debug]       if options[:debug]
      Matsuri::Config.environment = options[:environment] if options[:environment]
    end
  end
end
