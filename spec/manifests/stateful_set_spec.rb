# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'stateful_set manifest' do
  let(:manifest) { JSON.parse(Matsuri::Registry.stateful_set('db').new.to_json) }

  it 'renders the golden manifest through the pod template' do
    expect(manifest).to eq(
      'apiVersion' => 'apps/v1',
      'kind'       => 'StatefulSet',
      'metadata'   => {
        'name'      => 'db',
        'namespace' => 'specs',
        'labels'    => {
          'matsuri-name' => 'db',
          'matsuri-env'  => 'dev',
          'namespace'    => 'specs'
        },
        'annotations' => {}
      },
      'spec' => {
        'replicas' => 3,
        'selector' => { 'matchLabels' => { 'app' => 'db' } },
        'template' => {
          'metadata' => {
            'labels' => {
              'matsuri-name' => 'db',
              'matsuri-env'  => 'dev',
              'namespace'    => 'specs'
            },
            'annotations' => {}
          },
          'spec' => {
            'containers' => [{ 'name' => 'db', 'image' => 'postgres:latest' }]
          }
        },
        'serviceName'         => 'db',
        'podManagementPolicy' => 'OrderedReady',
        'updateStrategy'      => {
          'type'          => 'RollingUpdate',
          'rollingUpdate' => { 'partition' => 0 }
        },
        'volumeClaimTemplates' => [
          {
            'metadata' => { 'name' => 'data' },
            'spec' => {
              'accessModes'      => ['ReadWriteOnce'],
              'storageClassName' => 'ssd',
              'resources'        => { 'requests' => { 'storage' => '10Gi' } }
            }
          }
        ]
      }
    )
  end
end
