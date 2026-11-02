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

    it 'routes through server-side apply under the field manager when the resource declares apply_via :server_side_apply' do
      allow(deployment).to receive(:apply_via).and_return(:server_side_apply)
      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: true))
      expect_task(ops::ServerSideApply,
                  input:         deployment.applied_to_yaml,
                  field_manager: 'matsuri',
                  description:   'deployment/web')
      ops.apply(deployment)
    end

    it 'applies a server-side resource that is not live through the seeding protocol' do
      allow(deployment).to receive(:apply_via).and_return(:server_side_apply)
      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: false))
      seed = instance_double(Matsuri::Tasks::Stacks::Seed, run!: true)
      expect(Matsuri::Tasks::Stacks::Seed).to receive(:new)
        .with(hash_including(seeded: deployment.to_yaml, declared: deployment.applied_to_yaml))
        .and_return(seed)
      ops.apply(deployment)
    end

    it 'is fatal on an unknown apply_via' do
      allow(deployment).to receive(:apply_via).and_return(:sideways)
      expect { ops.apply(deployment) }.to raise_error(ArgumentError, /sideways/)
    end
  end

  describe '.consults_last_applied?' do
    it 'is true only for client-side apply' do
      expect(ops.consults_last_applied?(:apply)).to be true
      expect(ops.consults_last_applied?(:replace)).to be false
      expect(ops.consults_last_applied?(:server_side_apply)).to be false
    end

    it 'is fatal on an unknown apply_via' do
      expect { ops.consults_last_applied?(:sideways) }.to raise_error(ArgumentError, /sideways/)
    end
  end

  describe '.create' do
    it 'passes the save_config policy through' do
      allow(config_map).to receive(:save_config).and_return(false)
      expect_task(ops::Create, input: config_map.to_yaml, save_config: false)
      ops.create(config_map)
    end

    it 'pins save_config false when ongoing delivery never consults last-applied' do
      allow(config_map).to receive(:apply_via).and_return(:replace)
      expect_task(ops::Create, input: config_map.to_yaml, save_config: false)
      ops.create(config_map)
    end

    it 'creates a server-side resource through the seeding protocol' do
      allow(config_map).to receive(:apply_via).and_return(:server_side_apply)
      seed = instance_double(Matsuri::Tasks::Stacks::Seed, run!: true)
      expect(Matsuri::Tasks::Stacks::Seed).to receive(:new)
        .with(hash_including(seeded: config_map.to_yaml, field_manager: 'matsuri'))
        .and_return(seed)
      ops.create(config_map)
    end
  end

  describe '.recreate' do
    it 'pins save_config false when ongoing delivery never consults last-applied' do
      allow(config_map).to receive(:apply_via).and_return(:replace)
      create = instance_double(ops::Create)
      expect(ops::Create).to receive(:new).with(hash_including(save_config: false)).and_return(create)
      expect_task(ops::Recreate, name: 'app-settings', create: create)
      ops.recreate(config_map)
    end

    it 'recreates a server-side resource through the seeding protocol after teardown' do
      allow(config_map).to receive(:apply_via).and_return(:server_side_apply)
      seed = instance_double(Matsuri::Tasks::Stacks::Seed)
      allow(Matsuri::Tasks::Stacks::Seed).to receive(:new).and_return(seed)
      expect_task(ops::Recreate, name: 'app-settings', create: seed)
      ops.recreate(config_map)
    end
  end

  describe '.diff' do
    it 'diffs the same payload apply would send' do
      expect_task(ops::Diff,
                  input:       deployment.applied_to_yaml,
                  namespace:   'specs',
                  description: 'deployment/web',
                  server_side: false)
      ops.diff(deployment)
    end

    it 'routes --server-side through under the same manager apply delivers with' do
      allow(deployment).to receive(:apply_via).and_return(:server_side_apply)
      expect_task(ops::Diff, server_side: true, field_manager: 'matsuri')
      ops.diff(deployment)
    end
  end

  describe 'present scenarios' do
    let(:presenters) { { on_apply: ['team-label'], on_create: ['team-label'] } }

    it 'apply assembles :on_apply' do
      task = instance_double(ops::Apply, run!: true)
      expect(ops::Apply).to receive(:new) do |args|
        expect(args[:input]).to match(/team: platform/)
        task
      end
      ops.apply(deployment, presenters: presenters)
    end

    it 'create assembles :on_create' do
      task = instance_double(ops::Create, run!: true)
      expect(ops::Create).to receive(:new) do |args|
        expect(args[:input]).to match(/team: platform/)
        task
      end
      ops.create(config_map, presenters: presenters)
    end

    it 'diff sends exactly the payload apply would send, presented' do
      expect(ops.apply_payload(deployment, presenters))
        .to eq ops.presentation(deployment.applied_manifest_for_export, presenters, :on_apply).to_yaml
      expect(ops.apply_payload(deployment, presenters)).to match(/team: platform/)
    end

    it 'the empty pipeline is byte-identical to the rendered payload' do
      expect(ops.apply_payload(deployment, {})).to eq deployment.applied_to_yaml
    end

    it 'presents multi-doc manifests per document' do
      docs = [
        { 'kind' => 'Deployment', 'metadata' => { 'name' => 'web' } },
        { 'kind' => 'Service',    'metadata' => { 'name' => 'web' } }
      ]
      matched = { on_apply: [Matsuri::Transform::Combinators.match_deployments('team-label')] }
      presented = ops.presentation(docs, matched, :on_apply)

      expect(presented[0]['metadata']['labels']).to eq('team' => 'platform')
      expect(presented[1]['metadata']).not_to have_key('labels')
      expect(ops.serialize(presented).scan(/^---$/).length).to eq 2
    end
  end

  describe '.manifest' do
    it 'reads the live manifest with identity derived from the resource' do
      get = instance_double(ops::Get, manifest: { 'kind' => 'Deployment' })
      expect(ops::Get).to receive(:new)
        .with(hash_including(resource_type: 'deployment', name: 'web', namespace: 'specs'))
        .and_return(get)
      expect(ops.manifest(deployment)).to eq('kind' => 'Deployment')
    end
  end

  describe '.status' do
    it 'displays live state with identity derived from the resource' do
      expect_task(ops::Status, resource_type: 'deployment', name: 'web', namespace: 'specs')
      ops.status(deployment)
    end
  end

  describe '.rollout_status' do
    it 'watches the rollout with identity derived from the resource' do
      expect_task(ops::RolloutStatus, resource_type: 'deployment', name: 'web', namespace: 'specs')
      ops.rollout_status(deployment)
    end
  end

  describe '.converge' do
    it 'converges via apply by default' do
      expect_task(ops::Apply, description: 'deployment/web')
      ops.converge(deployment)
    end

    it 'converges a server-side resource through the seeding protocol when nothing is live' do
      allow(deployment).to receive(:apply_via).and_return(:server_side_apply)
      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: false))
      seed = instance_double(Matsuri::Tasks::Stacks::Seed, run!: true)
      expect(Matsuri::Tasks::Stacks::Seed).to receive(:new)
        .with(hash_including(seeded:        deployment.to_yaml,
                             declared:      deployment.applied_to_yaml,
                             description:   'deployment/web',
                             field_manager: 'matsuri'))
        .and_return(seed)
      ops.converge(deployment)
    end

    it 'converges a live server-side resource by ordinary server-side apply' do
      allow(deployment).to receive(:apply_via).and_return(:server_side_apply)
      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: true))
      expect_task(ops::ServerSideApply, field_manager: 'matsuri', description: 'deployment/web')
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
      create = instance_double(ops::Create)
      expect(ops::Create).to receive(:new).with(hash_including(save_config: true)).and_return(create)
      expect_task(ops::Recreate,
                  resource_type: 'configmap',
                  name:          'app-settings',
                  create:        create)
      ops.converge(config_map, { restart: true })
    end
  end
end
