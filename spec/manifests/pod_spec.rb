# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'pod manifest' do
  let(:manifest) { JSON.parse(Matsuri::Registry.pod('hello').new.to_json) }

  it 'renders the golden manifest' do
    expect(manifest).to eq(
      'apiVersion' => 'v1',
      'kind'       => 'Pod',
      'metadata'   => {
        'name'      => 'hello',
        'namespace' => 'specs',
        'labels'    => {
          'matsuri-name' => 'hello',
          'matsuri-env'  => 'dev',
          'namespace'    => 'specs'
        },
        'annotations' => {}
      },
      'spec' => {
        'containers' => [{ 'name' => 'hello', 'image' => 'nginx:1.25' }]
      }
    )
  end

  it 'defaults each resource request to its own limit' do
    klass = Matsuri.define(:pod, 'limits-only', inherits: 'hello') do
      let(:cpu_limit) { '500m' }
      let(:mem_limit) { '1Gi' }
      let(:spec)      { { containers: [container] } }
      let(:container) { { name: 'c', image: 'i', resources: resources } }
    end
    rendered = JSON.parse(klass.new.to_json)

    expect(rendered['spec']['containers'][0]['resources']).to eq(
      'requests' => { 'cpu' => '500m', 'memory' => '1Gi' },
      'limits'   => { 'cpu' => '500m', 'memory' => '1Gi' }
    )
  end

  it 'merges a metadata override over default_metadata' do
    klass = Matsuri.define(:pod, 'metadata-merge', inherits: 'hello') do
      let(:metadata) { { finalizers: ['matsuri.spec/golden'] } }
    end
    rendered = JSON.parse(klass.new.to_json)

    expect(rendered['metadata']['finalizers']).to eq ['matsuri.spec/golden']
    expect(rendered['metadata']['name']).to eq 'metadata-merge'
  end
end
