# frozen_string_literal: true

require 'spec_helper'

# The dialect is Algebra + Env addressed to Kubernetes manifest shapes.
# Well-known paths are constants, so append_node_affinity passing pins the
# node selector path spelling by construction.
RSpec.describe Matsuri::Transform::Kubernetes do
  subject(:dialect) { described_class }

  let(:spec) do
    Map.new(
      containers: [
        { name: 'app',     image: 'app:1', env: [{ name: 'A', value: '1' }] },
        { name: 'sidecar', image: 'sidecar:1', env: [] }
      ],
      volumes: []
    )
  end

  describe '.set_env' do
    it 'updates an existing variable on container 0 by default' do
      dialect.set_env(spec, 'A', '9')
      expect(spec.get(:containers, 0, :env, 0, :value)).to eq '9'
    end

    it 'appends a new variable to the addressed container' do
      dialect.set_env(spec, 'B', '2', container: 1)
      expect(spec.get(:containers, 1, :env).map { |e| e[:name] }).to eq ['B']
    end
  end

  describe '.set_all_env' do
    it 'sets the variable on every container' do
      dialect.set_all_env(spec, 'B', '2')
      expect(spec.get(:containers).map { |c| c[:env].map { |e| e[:name] } }).to eq [%w[A B], %w[B]]
    end

    it 'is the zero point when there are no containers' do
      empty = Map.new(containers: [])
      expect(dialect.set_all_env(empty, 'B', '2')).to eq Map.new(containers: [])
    end
  end

  describe '.set_resources' do
    let(:resources) { { requests: { cpu: '100m' } } }

    it 'addresses the container by name' do
      dialect.set_resources(spec, resources, container_name: 'sidecar')
      expect(spec.get(:containers, 1, :resources, :requests, :cpu)).to eq '100m'
    end

    it 'raises EntryNotFound for an unknown container name' do
      expect { dialect.set_resources(spec, resources, container_name: 'ghost') }
        .to raise_error(Matsuri::Transform::EntryNotFound, /ghost/)
    end
  end

  describe '.with_resources' do
    it 'curries the container name and resource spec into a spec -> spec step' do
      step = dialect.with_resources('app', { limits: { memory: '128Mi' } })
      expect(step.(spec).get(:containers, 0, :resources, :limits, :memory)).to eq '128Mi'
    end
  end

  describe '.set_label' do
    it 'writes the label through the metadata' do
      metadata = Map.new(labels: { app: 'web' })
      dialect.set_label(metadata, :team, 'platform')
      expect(metadata.get(:labels, :team)).to eq 'platform'
    end
  end

  describe 'volumes' do
    it 'appends a volume' do
      dialect.append_volume(spec, name: 'data', emptyDir: {})
      expect(spec.get(:volumes).map { |v| v['name'] }).to eq ['data']
    end

    it 'appends a volume mount to the addressed container' do
      spec.set([:containers, 0, :volumeMounts], [])
      dialect.append_volume_mount(spec, { name: 'data', mountPath: '/data' })
      expect(spec.get(:containers, 0, :volumeMounts, 0, :mountPath)).to eq '/data'
    end
  end

  describe '.without_container' do
    it 'removes the named container' do
      dialect.without_container(spec, name: 'sidecar')
      expect(spec.get(:containers).map { |c| c['name'] }).to eq ['app']
    end
  end

  describe 'node affinity' do
    let(:scheduling) do
      Map.new(affinity: { nodeAffinity: { requiredDuringSchedulingIgnoredDuringExecution: { nodeSelectorTerms: [] } } })
    end

    it 'appends match expressions through the well-known path' do
      dialect.append_node_affinity(scheduling, matchExpressions: [{ key: 'zone', operator: 'In', values: ['a'] }])
      terms = scheduling.get(*described_class::NODE_SELECTOR_TERMS_PATH)
      expect(terms.length).to eq 1
      expect(terms.first.get(:matchExpressions, 0, :key)).to eq 'zone'
    end

    it 'updates node selector terms with the transform function' do
      dialect.update_in_node_selector_terms(scheduling) { |terms| terms + [{ matchFields: [] }] }
      expect(scheduling.get(*described_class::NODE_SELECTOR_TERMS_PATH).length).to eq 1
    end
  end
end
