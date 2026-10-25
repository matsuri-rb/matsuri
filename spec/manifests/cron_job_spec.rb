# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'cron_job manifest' do
  let(:manifest) { JSON.parse(Matsuri::Registry.cron_job('report').new.to_json) }

  it 'renders the golden manifest through the pod template' do
    expect(manifest).to eq(
      'apiVersion' => 'batch/v1',
      'kind'       => 'CronJob',
      'metadata'   => {
        'name'      => 'report',
        'namespace' => 'specs',
        'labels'    => {
          'matsuri-name' => 'report',
          'matsuri-env'  => 'dev',
          'namespace'    => 'specs'
        },
        'annotations' => {}
      },
      'spec' => {
        'schedule'    => '0 4 * * *',
        'jobTemplate' => {
          'metadata' => {
            'labels' => {
              'matsuri-name' => 'report',
              'matsuri-env'  => 'dev',
              'namespace'    => 'specs'
            },
            'annotations' => {}
          },
          'spec' => {
            'template' => {
              'metadata' => {
                'labels' => {
                  'matsuri-name' => 'report',
                  'matsuri-env'  => 'dev',
                  'namespace'    => 'specs'
                },
                'annotations' => {}
              },
              'spec' => {
                'containers' => [{ 'name' => 'report', 'image' => 'report:latest' }]
              }
            }
          }
        }
      }
    )
  end

  it 'renders timeZone in camelCase when set' do
    klass = Matsuri.define(:cron_job, 'report-tz', inherits: 'report') do
      let(:time_zone) { 'America/Los_Angeles' }
    end
    rendered = JSON.parse(klass.new.to_json)

    expect(rendered['spec']['timeZone']).to eq 'America/Los_Angeles'
    expect(rendered['spec'].key?('time_zone')).to be false
  end
end
