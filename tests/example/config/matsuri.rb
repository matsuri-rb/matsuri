# Overrides Matsuri::Config

# Environment names are not kubectl context names here; each
# environment names its context in config/platform.rb
map_env_to_kube_context true

# Should not be storing secrets locally
# This is for demonstration only
default(:config_secrets_path) { File.join base_path, 'etc', 'secrets' }
