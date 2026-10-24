require 'spec_helper'

RSpec.describe 'deployment manifest' do
  let(:manifest) { JSON.parse(Matsuri::Registry.deployment('web').new.to_json) }

  it 'renders the golden manifest through the pod template' do
    expect(manifest).to eq(
      'apiVersion' => 'apps/v1',
      'kind'       => 'Deployment',
      'metadata'   => {
        'name'      => 'web',
        'namespace' => 'specs',
        'labels'    => {
          'matsuri-name' => 'web',
          'matsuri-env'  => 'dev',
          'namespace'    => 'specs'
        },
        'annotations' => {}
      },
      'spec' => {
        'replicas' => 2,
        'selector' => {
          'matchLabels'      => { 'app' => 'web' },
          'matchExpressions' => []
        },
        'template' => {
          'metadata' => {
            'labels' => {
              'matsuri-name' => 'web',
              'matsuri-env'  => 'dev',
              'namespace'    => 'specs'
            },
            'annotations' => {}
          },
          'spec' => {
            'containers' => [{ 'name' => 'web', 'image' => 'app:latest' }]
          }
        },
        'strategy' => {
          'type'          => 'RollingUpdate',
          'rollingUpdate' => { 'maxUnavailable' => 1, 'maxSurge' => 1 }
        },
        'minReadySeconds' => 0
      }
    )
  end

  it 'propagates image_tag options into the pod template' do
    rendered = JSON.parse(Matsuri::Registry.deployment('web').new(image_tag: 'v42').to_json)

    expect(rendered['spec']['template']['spec']['containers'][0]['image']).to eq 'app:v42'
  end
end
