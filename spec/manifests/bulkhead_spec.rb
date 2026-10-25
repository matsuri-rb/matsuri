# frozen_string_literal: true

require 'spec_helper'

# Bulkhead deployments over one shared podspec, parameterized through lazy
# options on two axes: app_role (web, worker) names the workload,
# resource_class (standard, streams, general) names the capacity class.
# The pod resolves class defaults from its table; every scalar remains an
# independent override point.
RSpec.describe 'bulkhead deployments over a shared podspec' do
  let(:web)     { JSON.parse(Matsuri::Registry.deployment('app-web').new.to_json) }
  let(:streams) { JSON.parse(Matsuri::Registry.deployment('app-web-streams').new.to_json) }
  let(:worker)  { JSON.parse(Matsuri::Registry.deployment('app-worker-general').new.to_json) }

  def container(manifest)
    manifest['spec']['template']['spec']['containers'][0]
  end

  def template_labels(manifest)
    manifest['spec']['template']['metadata']['labels']
  end

  it 'runs the same container image in every bulkhead' do
    [web, streams, worker].each do |manifest|
      expect(container(manifest)['image']).to eq 'app:latest'
    end
  end

  it 'resolves the standard class by default' do
    expect(container(web)['resources']).to eq(
      'requests' => { 'cpu' => '250m', 'memory' => '256Mi' },
      'limits'   => { 'memory' => '512Mi' }
    )
  end

  it 'resolves the streams class named by the deployment' do
    expect(container(streams)['resources']).to eq(
      'requests' => { 'cpu' => '1', 'memory' => '1Gi' },
      'limits'   => { 'memory' => '2Gi' }
    )
  end

  it 'resolves the general class on the worker role' do
    expect(container(worker)['resources']).to eq(
      'requests' => { 'cpu' => '500m', 'memory' => '512Mi' },
      'limits'   => { 'memory' => '1Gi' }
    )
  end

  it 'lets a single scalar override beat the class default' do
    klass = Matsuri.define(:deployment, 'app-web-fat', inherits: 'app-web') do
      let(:pod_options) { default_pod_options.merge(app_role: 'web', mem_limit: '4Gi') }
    end
    rendered = JSON.parse(klass.new.to_json)

    expect(container(rendered)['resources']).to eq(
      'requests' => { 'cpu' => '250m', 'memory' => '256Mi' },
      'limits'   => { 'memory' => '4Gi' }
    )
  end

  it 'stamps both identity axes into the pod template labels' do
    expect(template_labels(web)).to include('app_role' => 'web',    'resource_class' => 'standard')
    expect(template_labels(streams)).to include('app_role' => 'web',    'resource_class' => 'streams')
    expect(template_labels(worker)).to include('app_role' => 'worker', 'resource_class' => 'general')
  end

  it 'keeps each selector a subset of its template labels' do
    [web, streams, worker].each do |manifest|
      selector = manifest['spec']['selector']['matchLabels']
      expect(template_labels(manifest)).to include(selector)
    end
  end

  it 'keeps selectors pairwise disjoint so bulkheads never fight over pods' do
    selectors = [web, streams, worker].map { |m| m['spec']['selector']['matchLabels'] }

    selectors.combination(2) do |a, b|
      conflicting = (a.keys & b.keys).any? { |key| a[key] != b[key] }
      expect(conflicting).to be(true), "selectors can match the same pod: #{a} vs #{b}"
    end
  end

  it 'sizes the bulkheads independently' do
    expect(web['spec']['replicas']).to eq 4
    expect(streams['spec']['replicas']).to eq 2
    expect(worker['spec']['replicas']).to eq 2
  end

  describe 'service fronting the standard web bulkhead' do
    let(:service) { JSON.parse(Matsuri::Registry.service('app-web').new.to_json) }

    it 'selects on the same labels the deployment selects on' do
      expect(service['spec']['selector']).to eq web['spec']['selector']['matchLabels']
    end

    it 'selects pods the deployment actually creates' do
      expect(template_labels(web)).to include(service['spec']['selector'])
    end

    it 'renders the service essentials' do
      expect(service['kind']).to eq 'Service'
      expect(service['spec']['type']).to eq 'ClusterIP'
      expect(service['spec']['ports']).to eq [{ 'port' => 3000 }]
    end
  end
end
