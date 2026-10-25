# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Concerns::Pods::SpreadTopology' do
  let(:manifest) { JSON.parse(Matsuri::Registry.pod('spread-balanced').new.to_json) }

  it 'balances across zones through topologySpreadConstraints' do
    expect(manifest['spec']['topologySpreadConstraints']).to eq [
      {
        'maxSkew'           => 1,
        'topologyKey'       => 'topology.kubernetes.io/zone',
        'whenUnsatisfiable' => 'ScheduleAnyway',
        'labelSelector'     => { 'matchLabels' => { 'app_role' => 'spread-balanced' } }
      }
    ]
  end

  it 'composes with SpreadPods node exclusion in the same pod' do
    expect(manifest['spec']['affinity']['podAntiAffinity']).to eq(
      'preferredDuringSchedulingIgnoredDuringExecution' => [
        {
          'weight' => 100,
          'podAffinityTerm' => {
            'labelSelector' => { 'matchLabels' => { 'app_role' => 'spread-balanced' } },
            'namespaces'    => [],
            'topologyKey'   => 'kubernetes.io/hostname'
          }
        }
      ]
    )
  end

  it 'lets skew and enforcement be overridden granularly' do
    klass = Matsuri.define(:pod, 'spread-balanced-hard', inherits: 'spread-balanced') do
      let(:zone_max_skew)           { 2 }
      let(:zone_when_unsatisfiable) { 'DoNotSchedule' }
    end
    constraint = JSON.parse(klass.new.to_json)['spec']['topologySpreadConstraints'][0]

    expect(constraint['maxSkew']).to eq 2
    expect(constraint['whenUnsatisfiable']).to eq 'DoNotSchedule'
    expect(constraint['topologyKey']).to eq 'topology.kubernetes.io/zone'
  end

  it 'composes strategies by concatenation with the knob ladder' do
    klass = Matsuri.define(:pod, 'spread-both-domains', inherits: 'spread-balanced') do
      let(:topology_spread_constraints) { balance_across_zones + balance_across_nodes }
      let(:node_max_skew)               { 2 }
      let(:node_when_unsatisfiable)     { 'DoNotSchedule' }
    end
    constraints = JSON.parse(klass.new.to_json)['spec']['topologySpreadConstraints']

    expect(constraints.map { |c| c['topologyKey'] }).to eq %w[topology.kubernetes.io/zone kubernetes.io/hostname]
    expect(constraints[0]['maxSkew']).to eq 1
    expect(constraints[1]['maxSkew']).to eq 2
    expect(constraints[1]['whenUnsatisfiable']).to eq 'DoNotSchedule'
  end

  it 'tunes every domain at once through the shared knob' do
    klass = Matsuri.define(:pod, 'spread-wide-skew', inherits: 'spread-balanced') do
      let(:topology_spread_constraints) { balance_across_zones + balance_across_nodes }
      let(:spread_max_skew)             { 3 }
    end
    constraints = JSON.parse(klass.new.to_json)['spec']['topologySpreadConstraints']

    expect(constraints.map { |c| c['maxSkew'] }).to eq [3, 3]
  end

  it 'requires the includer to select a strategy' do
    klass = Matsuri.define(:pod, 'spread-topology-unselected') do
      include Matsuri::Concerns::Pods::SpreadTopology
      let(:labels)    { { 'app_role' => 'x' } }
      let(:cpu_limit) { '1' }
      let(:mem_limit) { '1Gi' }
      let(:volumes)   { [] }
      let(:container) { { name: 'c', image: 'i', resources: resources } }
    end

    expect { klass.new.to_json }.to raise_error(NotImplementedError, /topology_spread_constraints/)
  end
end
