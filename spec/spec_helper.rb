$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'matsuri'
require 'json'

FIXTURE_ROOT = File.expand_path('fixture', __dir__)

RSpec.configure do |config|
  config.before(:suite) do
    Matsuri::Config.base_path   = FIXTURE_ROOT
    Matsuri::Config.environment = 'dev'
    Matsuri::Platform.load_configuration(Matsuri::Config.platform_load_paths)
  end
end
