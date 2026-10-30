# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ingress manifest' do
  let(:manifest) { JSON.parse(Matsuri::Registry.ingress('web').new.to_json) }

  it 'renders the golden manifest in networking.k8s.io/v1 shape' do
    expect(manifest).to eq(
      'apiVersion' => 'networking.k8s.io/v1',
      'kind'       => 'Ingress',
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
        'ingressClassName' => 'nginx',
        'rules' => [
          {
            'host' => 'app.example.com',
            'http' => {
              'paths' => [
                {
                  'path'     => '/',
                  'pathType' => 'Prefix',
                  'backend'  => {
                    'service' => { 'name' => 'app-web', 'port' => { 'number' => 80 } }
                  }
                }
              ]
            }
          }
        ],
        'tls' => [{ 'hosts' => ['app.example.com'], 'secretName' => 'app-web-tls' }]
      }
    )
  end

  it 'names a port instead of numbering it when given a string' do
    ingress = Matsuri::Registry.ingress('web').new

    expect(ingress.backend(service: 'app-web', port: 'http'))
      .to eq(service: { name: 'app-web', port: { name: 'http' } })
  end
end
