# frozen_string_literal: true

require 'spec_helper'

# The boundary functions are the single site deriving task inputs from a
# rendered resource and reading its delivery policy lets. These specs pin
# the policy selection; the tasks' own specs pin the kubectl lines.
RSpec.describe Matsuri::Tasks::KubectlOps do
  let(:ops) { described_class }

  let(:deployment) { Matsuri::Registry.fetch_or_load(:deployment, 'web').new }
  let(:config_map) { Matsuri::Registry.fetch_or_load(:config_map, 'app-settings').new }

  def expect_task(task_class, with)
    task = instance_double(task_class, run!: true)
    expect(task_class).to receive(:new).with(hash_including(with)).and_return(task)
    task
  end

  describe '.apply' do
    it 'applies the rendered payload with identity derived from the resource' do
      expect_task(ops::Apply,
                  input:       deployment.applied_to_yaml,
                  namespace:   'specs',
                  description: 'deployment/web')
      ops.apply(deployment)
    end

    it 'routes through replace when the resource declares apply_via :replace' do
      allow(config_map).to receive(:apply_via).and_return(:replace)
      expect_task(ops::Replace, input: config_map.applied_to_yaml, description: 'configmap/app-settings')
      ops.apply(config_map)
    end
  end

  describe '.create' do
    it 'passes the save_config policy through' do
      allow(config_map).to receive(:save_config).and_return(false)
      expect_task(ops::Create, input: config_map.to_yaml, save_config: false)
      ops.create(config_map)
    end
  end

  describe '.status' do
    it 'displays live state with identity derived from the resource' do
      expect_task(ops::Status, resource_type: 'deployment', name: 'web', namespace: 'specs')
      ops.status(deployment)
    end
  end

  describe '.converge' do
    it 'converges via apply by default' do
      expect_task(ops::Apply, description: 'deployment/web')
      ops.converge(deployment)
    end

    it 'converges recreate-policy resources by create when nothing is live' do
      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: false))
      expect_task(ops::Create, description: 'configmap/app-settings', save_config: true)
      ops.converge(config_map)
    end

    it 'skips recreate-policy resources that are already live' do
      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: true))
      expect(ops::Create).not_to receive(:new)
      expect(ops::Recreate).not_to receive(:new)
      ops.converge(config_map)
    end

    it 'recreates recreate-policy resources on restart' do
      expect_task(ops::Recreate,
                  resource_type: 'configmap',
                  name:          'app-settings',
                  save_config:   true)
      ops.converge(config_map, restart: true)
    end
  end
end
