# frozen_string_literal: true

require 'spec_helper'

# Diffable is pure computation: declared manifest against a caller-supplied
# current manifest, filtered deltas out. Fetching and printing are pinned in
# the Tasks::HashDiff spec.
RSpec.describe Matsuri::Concerns::Diffable do
  let(:resource)   { Matsuri::Registry.fetch_or_load(:deployment, 'web').new }
  let(:config_map) { Matsuri::Registry.fetch_or_load(:config_map, 'app-settings').new }
  let(:current)    { JSON.parse(resource.to_json) }

  describe '#diff' do
    it 'returns no deltas when the current manifest matches the declaration' do
      expect(resource.diff(current)).to eq []
    end

    it 'reports drift relative to the declaration' do
      current['spec']['replicas'] = current['spec']['replicas'].to_i + 1
      expect(resource.diff(current).map { |delta| delta[1] }).to eq ['spec.replicas']
    end

    it 'filters out paths the cluster owns' do
      current['status'] = { 'readyReplicas' => 1 }
      current['metadata']['annotations'] ||= {}
      current['metadata']['annotations']['kubectl.kubernetes.io/last-applied-configuration'] = '{}'
      expect(resource.diff(current)).to eq []
    end
  end

  describe '#primary_container_diff' do
    it 'compares only the container projected by primary_container_path' do
      current['spec']['replicas'] = 99
      current['spec']['template']['spec']['containers'][0]['image'] = 'drifted:tag'
      deltas = resource.primary_container_diff(current)
      expect(deltas.map { |delta| delta[1] }).to eq ['image']
    end

    it 'is fatal on a resource without a declared primary_container_path' do
      config_map # registry load logs; force it before constraining Matsuri.log
      expect(Matsuri).to receive(:log).with(:fatal, /primary_container_path/).and_raise(SystemExit)
      expect { config_map.primary_container_diff(current) }.to raise_error(SystemExit)
    end
  end
end
