# frozen_string_literal: true

require 'spec_helper'

# Seeds complete a create payload and never contest a declaration:
# don't-clobber is structural — a field only seeds when the manifest
# omits it. The probe in tests/bin/probe-save-config.sh pins the cluster
# side of the model; these pin the payload side.
RSpec.describe 'seed presenters' do
  include Matsuri::Presenters::Helpers

  let(:workload) do
    Map.new(kind: 'Deployment',
            spec: { template: { spec: { containers: [
              { name: 'app' },
              { name: 'sidecar', image: 'sidecar:9', resources: { requests: { cpu: '50m' } } }
            ] } } })
  end

  describe 'SeedReplicas' do
    it 'seeds the boot count when the manifest omits replicas' do
      expect(seed_replicas(2).call(workload).get(:spec, :replicas)).to eq 2
    end

    it 'yields when the manifest declares replicas' do
      declared = Map.new(spec: { replicas: 5 })
      expect(seed_replicas(2).call(declared).get(:spec, :replicas)).to eq 5
    end
  end

  describe 'SeedImage' do
    it 'seeds only containers that carry no image' do
      seeded = seed_image('registry.example.com/app:boot').call(workload)
      containers = seeded.get(:spec, :template, :spec, :containers)
      expect(containers[0][:image]).to eq 'registry.example.com/app:boot'
      expect(containers[1][:image]).to eq 'sidecar:9'
    end

    it 'reaches bare pod manifests through the same rule' do
      pod = Map.new(kind: 'Pod', spec: { containers: [{ name: 'app' }] })
      expect(seed_image('app:boot').call(pod).get(:spec, :containers, 0, :image)).to eq 'app:boot'
    end
  end

  describe 'SeedResources' do
    it 'seeds only containers that carry no resources' do
      boot = { requests: { cpu: '500m', memory: '512Mi' } }
      seeded = seed_resources(boot).call(workload)
      containers = seeded.get(:spec, :template, :spec, :containers)
      expect(containers[0].get(:resources, :requests, :cpu)).to eq '500m'
      expect(containers[1].get(:resources, :requests, :cpu)).to eq '50m'
    end
  end

  describe 'the concern pattern' do
    it 'an unfilled hole fails fast at first read' do
      unfilled = Class.new(Matsuri::Presenter) { include Matsuri::Presenters::SeedReplicas }
      expect { unfilled.call(workload) }.to raise_error(NotImplementedError, /replicas/)
    end

    it 'a named definition fills the hole with a let' do
      named = Matsuri.define(:presenter, 'boot-size') do
        include Matsuri::Presenters::SeedReplicas
        let(:replicas) { 3 }
      end
      expect(named.call(workload).get(:spec, :replicas)).to eq 3
    end
  end

  describe 'through delivery' do
    let(:ops) { Matsuri::Tasks::KubectlOps }

    it 'completes the create payload and leaves the apply payload alone' do
      Matsuri.define(:deployment, 'seed-target', inherits: 'app-web') do
        let(:replicas) { nil }
      end
      stack = Matsuri.define(:stack, 'seed-boot') do
        needs :deployment, 'seed-target'
        present :on_create, match_deployments(seed_replicas(2))
      end

      member = stack.new.members.first
      expect(ops.payload(member.manifest_for_export,
                         ops.presenters_for(member, stack.presenters), :on_create))
        .to match(/replicas: 2/)
      expect(ops.apply_payload(member, stack.presenters)).not_to match(/replicas/)
    end
  end
end
