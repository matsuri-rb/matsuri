# frozen_string_literal: true

require 'spec_helper'

# A stack bundles the resources managed together as one converge act: the
# bulkhead deployments, the service fronting them, and the config map they
# share. The stack promises sequence, not topology — build_order is the
# apply order, and each member stays independently addressable through the
# registry.
RSpec.describe 'app stack' do
  let(:stack_class) { Matsuri::Registry.stack('app') }
  let(:stack)       { stack_class.new }

  it 'loads the definition from platform/stacks' do
    expect(stack_class.ancestors).to include Matsuri::Stack
    expect(stack.name).to eq 'app'
  end

  it 'converges members in definition sequence' do
    expect(stack_class.build_order.map { |type, name, _| [type, name] }).to eq [
      [:config_map, 'app-settings'],
      [:deployment, 'app-web'],
      [:deployment, 'app-web-streams'],
      [:deployment, 'app-worker-general'],
      [:service,    'app-web']
    ]
  end

  it 'resolves every member to a renderable definition' do
    kinds = { config_map: 'ConfigMap', deployment: 'Deployment', service: 'Service' }

    stack_class.build_order.each do |(type, name, _)|
      manifest = JSON.parse(stack.dep(type, name).new.to_json)
      expect(manifest['kind']).to eq kinds.fetch(type)
      expect(manifest['metadata']['name']).to eq name
    end
  end

  it 'bundles the settings the workloads share' do
    config_map = JSON.parse(Matsuri::Registry.config_map('app-settings').new.to_json)

    expect(config_map['data']).to eq(
      'LOG_LEVEL'    => 'info',
      'WORKER_QUEUE' => 'default'
    )
  end

  it 'resolves image_tag through the built-in acceptor' do
    expect(stack.image_tag).to eq 'latest'
    expect(stack_class.new(image_tag: 'v42').image_tag).to eq 'v42'
  end

  it 'overrides a built-in acceptor by re-declaring its collection, locally to the declaring stack' do
    pinned = Class.new(Matsuri::Acceptor) do
      let(:image_tag) { options[:image_tag] || 'pinned' }
    end

    custom = Matsuri.define(:stack, 'app-pinned') do
      needs :deployment, 'app-web'
    end
    custom.accept :image_tag, pinned

    expect(custom.new.image_tag).to eq 'pinned'
    expect(stack_class.new.image_tag).to eq 'latest'
  end

  it 'keeps build order local to each stack' do
    other = Matsuri.define(:stack, 'app-canary') do
      needs :deployment, 'app-web'
    end

    expect(other.build_order.map { |_, name, _| name }).to eq ['app-web']
    expect(stack_class.build_order.length).to eq 5
  end
end
