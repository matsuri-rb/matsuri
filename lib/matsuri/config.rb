# This file aggregates all the different configs for the tests

require 'mixlib/config'
require 'pathname'

module Matsuri
  module Config
    extend Mixlib::Config
    config_strict_mode true  # will see how annoying this is

    # Base path of the platform repo, defaults to PWD
    default :base_path, ENV['PWD']
    default :verbose, false
    default :debug, false

    # Container Image Versions
    default :etcd_version,      nil # 2.0.12
    default :hyperkube_version, nil # v1.0.1

    # Networking
    default :etcd_addr,        '127.0.0.1:4001'
    default :etcd_bind_addr,   '0.0.0.0:4001'
    default :master_addr,      '127.0.0.1'
    default :master_bind_addr, '0.0.0.0'
    default :api_servers,      'http://localhost:8080'
    default :master_url,       'http://127.0.0.1:8080'

    # Platform paths
    default(:config_path)   { File.join base_path, 'config', 'config.rb' }
    default(:secrets_path)  { File.join config_path, 'secrets' }
    default(:build_path)    { File.join base_path, 'build' }
    default(:docker_path)   { File.join base_path, 'docker' }
    default(:source_path)   { File.join base_path, 'src' }
    default(:lib_path)      { File.join base_path, 'lib' }
    default(:platform_path) { File.join base_path, 'platform' }
    default(:images_path)   { File.join platform_path, 'images' }
    default(:pods_path)     { File.join platform_path, 'pods' }
    default(:services_path) { File.join platform_path, 'services' }

    default :manifests_path, '/etc/kubernetes/manifests'

    # Helpers
    def self.host_osx?
      /darwin/ =~ RUBY_PLATFORM
    end

  end
end
