# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Concerns::Pods::SpreadPods' do
  let(:manifest) { JSON.parse(Matsuri::Registry.pod('spread-worker').new.to_json) }
  let(:anti_affinity) { manifest['spec']['affinity']['podAntiAffinity'] }

  it 'renders required one-per-zone anti-affinity over the pod labels' do
    expect(anti_affinity).to eq(
      'requiredDuringSchedulingIgnoredDuringExecution' => [
        {
          'labelSelector' => { 'matchLabels' => { 'app_role' => 'spread-worker' } },
          'namespaces'    => [],
          'topologyKey'   => 'topology.kubernetes.io/zone'
        }
      ]
    )
  end

  it 'renders required one-per-node anti-affinity on the hostname key' do
    rendered = JSON.parse(Matsuri::Registry.pod('spread-one-per-node').new.to_json)
    anti = rendered['spec']['affinity']['podAntiAffinity']

    expect(anti).to eq(
      'requiredDuringSchedulingIgnoredDuringExecution' => [
        {
          'labelSelector' => { 'matchLabels' => { 'app_role' => 'spread-one-per-node' } },
          'namespaces'    => [],
          'topologyKey'   => 'kubernetes.io/hostname'
        }
      ]
    )
  end

  it 'renders preferred spreading as weighted terms' do
    klass = Matsuri.define(:pod, 'spread-preferred', inherits: 'spread-worker') do
      let(:pod_anti_affinity) { prefer_one_per_node }
    end
    rendered = JSON.parse(klass.new.to_json)
    preferred = rendered['spec']['affinity']['podAntiAffinity']['preferredDuringSchedulingIgnoredDuringExecution']

    expect(preferred).to eq [
      {
        'weight' => 100,
        'podAffinityTerm' => {
          'labelSelector' => { 'matchLabels' => { 'app_role' => 'spread-worker' } },
          'namespaces'    => [],
          'topologyKey'   => 'kubernetes.io/hostname'
        }
      }
    ]
  end

  it 'lets the zone topology key be overridden' do
    klass = Matsuri.define(:pod, 'spread-custom-zone', inherits: 'spread-worker') do
      let(:zone_topology_key) { 'example.com/rack' }
    end
    rendered = JSON.parse(klass.new.to_json)
    term = rendered['spec']['affinity']['podAntiAffinity']['requiredDuringSchedulingIgnoredDuringExecution'][0]

    expect(term['topologyKey']).to eq 'example.com/rack'
  end

  it 'requires the includer to select a strategy' do
    klass = Matsuri.define(:pod, 'spread-unselected') do
      include Matsuri::Concerns::Pods::SpreadPods
      let(:labels)    { { 'app_role' => 'x' } }
      let(:cpu_limit) { '1' }
      let(:mem_limit) { '1Gi' }
      let(:volumes)   { [] }
      let(:container) { { name: 'c', image: 'i', resources: resources } }
    end

    expect { klass.new.to_json }.to raise_error(NotImplementedError, /pod_anti_affinity/)
  end
end
