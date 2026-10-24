require 'spec_helper'
require 'open3'

# Each constant is loaded FIRST in a fresh process. Autoload graphs make load
# order caller-dependent; this pins the orderings that have broken before
# (e.g. Registry-first exposed rlet/lazy_options requiring Concern unloaded).
RSpec.describe 'load order' do
  ENTRY_CONSTANTS = %w[
    Matsuri::Initializer
    Matsuri::Config
    Matsuri::Platform
    Matsuri::ShellOut
    Matsuri::Registry
    Matsuri::Task
    Matsuri::Cmd
    Matsuri::App
    Matsuri::Cmds::Cli
    Matsuri::Kubernetes::Base
    Matsuri::Tasks::Cluster
    Matsuri::Concerns::ExportManifest
    Matsuri::DSL::Cluster::Scope
    Matsuri::DSL::Cluster::AggregatedClusterRole
  ].freeze

  lib = File.expand_path('../lib', __dir__)

  ENTRY_CONSTANTS.each do |const|
    it "loads cleanly when #{const} is touched first" do
      _out, err, status = Open3.capture3(
        RbConfig.ruby, '-I', lib, '-r', 'matsuri',
        '-e', "Object.const_get(#{const.inspect})"
      )

      expect(status).to be_success, "touching #{const} first failed:\n#{err}"
    end
  end
end
