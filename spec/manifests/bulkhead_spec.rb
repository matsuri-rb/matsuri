require 'spec_helper'

# Two deployments share one podspec; each parameterizes it through lazy
# options (RLet::LazyOptions): identity via the app_role label, capacity
# via resource requests/limits.
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

  it 'overrides capacity for the web-streams bulkhead from the deployment' do
    expect(container(streams)['resources']).to eq(
      'requests' => { 'cpu' => '1', 'memory' => '1Gi' },
      'limits'   => { 'memory' => '2Gi' }
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
end
