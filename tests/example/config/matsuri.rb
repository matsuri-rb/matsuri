# Overrides Matsuri::Config

# Should not be storing secrets locally
# This is for demonstration only
default(:config_secrets_path) { File.join base_path, 'etc', 'secrets' }
