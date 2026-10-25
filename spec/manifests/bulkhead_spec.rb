# frozen_string_literal: true

require 'spec_helper'

# Two deployments share one podspec; each parameterizes it through lazy
# options (RLet::LazyOptions). Identity travels as the app_role label;
# capacity travels as granular scalars (cpu_request, mem_request,
# cpu_limit, mem_limit) — each independently overridable, with the
# nested resources structure assembled only in the pod.
RSpec.describe 'bulkhead deployments over a shared podspec' do
  let(:web)     { JSON.parse(Matsuri::Registry.deployment('app-web').new.to_json) }
  let(:streams) { JSON.parse(Matsuri::Registry.deployment('app-web-streams').new.to_json) }

  def container(manifest)
    manifest['spec']['template']['spec']['containers'][0]
  end

  def template_labels(manifest)
    manifest['spec']['template']['metadata']['labels']
  end

  it 'runs the same container image in both bulkheads' do
    expect(container(web)['image']).to eq 'app:latest'
    expect(container(streams)['image']).to eq 'app:latest'
  end

  it 'keeps pod defaults in the web bulkhead' do
    expect(container(web)['resources']).to eq(
      'requests' => { 'cpu' => '250m', 'memory' => '256Mi' },
      'limits'   => { 'memory' => '512Mi' }
    )
  end

  it 'overrides each scalar independently for the web-streams bulkhead' do
    expect(container(streams)['resources']).to eq(
      'requests' => { 'cpu' => '1', 'memory' => '1Gi' },
      'limits'   => { 'memory' => '2Gi' }
    )
  end

  it 'preserves untouched scalars when only one is overridden' do
    klass = Matsuri.define(:deployment, 'app-web-fat', inherits: 'app-web') do
      let(:pod_options) { default_pod_options.merge(app_role: 'web', mem_limit: '4Gi') }
    end
    rendered = JSON.parse(klass.new.to_json)

    expect(container(rendered)['resources']).to eq(
      'requests' => { 'cpu' => '250m', 'memory' => '256Mi' },
      'limits'   => { 'memory' => '4Gi' }
    )
  end

  it 'stamps app_role identity into the pod template labels' do
    expect(template_labels(web)['app_role']).to eq 'web'
    expect(template_labels(streams)['app_role']).to eq 'web-streams'
  end

  it 'keeps each selector a subset of its template labels' do
    [web, streams].each do |manifest|
      selector = manifest['spec']['selector']['matchLabels']
      expect(template_labels(manifest)).to include(selector)
    end
  end

  it 'sizes the bulkheads independently' do
    expect(web['spec']['replicas']).to eq 4
    expect(streams['spec']['replicas']).to eq 2
  end

  describe 'service fronting the web bulkhead' do
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
