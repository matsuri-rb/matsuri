require 'mixlib/config'
require 'pathname'

module Matsuri
  # This contains configs specific to the platform. Unlike Matsuri::Config, these
  # is freeform. Think of it as a key-value store which can be loaded and layered
  # from a set of files. You would define the list of platform config files to load,
  # and Matsuri will load those values in here. Files loaded later will override values
  # loaded from earlier files.
  #
  # Platform config is where you will put things like dev secrets, API test keys, to
  # fill into the environment spec for Kubernetes pods.
  module Platform
    extend Mixlib::Config
    config_strict_mode false # Allow users to extend the key space

    # Loads a platform file if it exists. Each subsequent file loaded
    # will override older ones.
    def self.load_configuration(load_paths = [])
      load_paths.each do |path|
        next unless File.file?(path)
        from_file(path)
      end
    end
  end
end
