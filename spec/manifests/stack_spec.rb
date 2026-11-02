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
      let(:image_tag) { options || 'pinned' }
    end

    custom = Matsuri.define(:stack, 'app-pinned') do
      needs :deployment, 'app-web'
    end
    custom.accept :image_tag, pinned

    expect(custom.new.image_tag).to eq 'pinned'
    expect(stack_class.new.image_tag).to eq 'latest'
  end

  it 'admits nothing through :config until a platform re-declares it' do
    expect(stack.stack_config).to be_a Matsuri::Acceptor
    expect { stack.stack_config.log_level }.to raise_error(NoMethodError)
  end

  it 'admits stack-config through a platform-declared acceptor, named in the registry' do
    configured = Matsuri.define(:stack, 'app-configured') do
      accept :config, 'app'
      needs :deployment, 'app-web'
    end

    expect(configured.new(config: { log_level: 'debug' }).stack_config.log_level).to eq 'debug'
    expect(configured.new.stack_config.log_level).to eq 'info'
  end

  it 'projects each collection its own component of the options' do
    configured = Matsuri.define(:stack, 'app-projected') do
      accept :config, 'app'
      needs :deployment, 'app-web'
    end

    instance = configured.new(image_tag: 'v42', config: { name: 'app-feat' })

    expect(instance.image_tag).to eq 'v42'
    expect(instance.stack_config.instance_name).to eq 'app-feat'
    expect(instance.stack_config.artifact).to eq(name: 'app-feat')
  end

  it 'binds one acceptor instance per converge and hands it to every resource member' do
    instance = stack_class.new(config: { log_level: 'debug' })

    members = instance.members
    expect(members.length).to eq 5
    expect(members.map(&:stack_config)).to all(be(instance.stack_config))
  end

  it 'passes the acceptor instance through the pod template to pod definitions' do
    instance   = stack_class.new(config: { log_level: 'debug' })
    deployment = instance.members.find { |m| m.is_a?(Matsuri::Kubernetes::Deployment) }

    expect(deployment.pod_def.stack_config).to be instance.stack_config
  end

  it 'never passes stack-config across a stack boundary' do
    expect(stack.dep_options(:deployment)).to have_key(:stack_config)
    expect(stack.dep_options(:stack)).not_to have_key(:stack_config)
  end

  it 'delivers docker! through the Docker task; stacks do not shell out' do
    docker = instance_double(Matsuri::Tasks::Docker)
    expect(Matsuri::Tasks::Docker).to receive(:new).and_return(docker)
    expect(docker).to receive(:run!).with('build -t app .', {})

    stack.docker!('build -t app .')
    expect(stack).not_to respond_to(:kubectl!)
  end

  it 'keeps build order local to each stack' do
    other = Matsuri.define(:stack, 'app-canary') do
      needs :deployment, 'app-web'
    end

    expect(other.build_order.map { |_, name, _| name }).to eq ['app-web']
    expect(stack_class.build_order.length).to eq 5
  end
end
