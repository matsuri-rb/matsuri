# frozen_string_literal: true

require 'spec_helper'

# Pod-scoped cluster reads, parameterized — identity and selectors arrive
# as options, never read off a resource. pod_selector_for is the bridge:
# it derives the flat label selector from what each kind declares.
RSpec.describe Matsuri::Tasks::Pod do
  def live_lookup(success, stdout: '')
    instance_double(Mixlib::ShellOut,
                    status: instance_double(Process::Status, success?: success),
                    stdout: stdout)
  end

  describe '#up?' do
    let(:task) { described_class.new(name: 'web', namespace: 'specs') }

    def pod_json(phase:, ready:)
      JSON.generate('status' => {
                      'phase'             => phase,
                      'containerStatuses' => [{ 'ready' => ready }]
                    })
    end

    it 'is up when Running with every container ready' do
      expect(task).to receive(:shell_out)
        .with('kubectl --context=dev --namespace=specs get pod/web -o json', { echo_level: :debug, no_stdout: true })
        .and_return(live_lookup(true, stdout: pod_json(phase: 'Running', ready: true)))
      expect(task.up?).to be true
    end

    it 'is not up while pending' do
      allow(task).to receive(:shell_out).and_return(live_lookup(true, stdout: pod_json(phase: 'Pending', ready: false)))
      expect(task.up?).to be false
    end

    it 'is not up until every container is ready' do
      allow(task).to receive(:shell_out).and_return(live_lookup(true, stdout: pod_json(phase: 'Running', ready: false)))
      expect(task.up?).to be false
    end
  end

  describe '#selected_pods' do
    it 'lists live pods by the label selector' do
      task = described_class.new(namespace: 'specs', selector: { app: 'web', tier: 'frontend' })
      expect(task).to receive(:shell_out)
        .with('kubectl --context=dev --namespace=specs get pods -l app=web,tier=frontend -o json', { echo_level: :debug, no_stdout: true })
        .and_return(live_lookup(true, stdout: '{"items":[{"metadata":{"name":"web-1"}}]}'))
      expect(task.selected_pods.first['metadata']['name']).to eq 'web-1'
    end
  end

  describe '.pod_selector_for' do
    it 'reads match_labels from workloads' do
      deployment = Matsuri::Registry.deployment('app-web').new
      expect(described_class.pod_selector_for(deployment)).to eq deployment.match_labels
    end

    it 'reads the flat selector from services' do
      service = Matsuri::Registry.service('app-web').new
      expect(described_class.pod_selector_for(service)).to eq service.selector
    end

    it 'refuses resources that do not select pods' do
      config_map = Matsuri::Registry.config_map('app-settings').new
      expect { described_class.pod_selector_for(config_map) }.to raise_error(ArgumentError, /does not select pods/)
    end
  end
end
