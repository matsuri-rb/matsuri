# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Get do
  let(:task) do
    described_class.new(resource_type: 'deployment', name: 'web', namespace: 'specs')
  end

  def live_lookup(success, stdout: '')
    instance_double(Mixlib::ShellOut,
                    status: instance_double(Process::Status, success?: success),
                    stdout: stdout)
  end

  it 'reports existence from the live lookup' do
    expect(task).to receive(:shell_out)
      .with('kubectl --context=dev --namespace=specs get deployment/web', { echo_level: :debug, no_stdout: true })
      .and_return(live_lookup(true))
    expect(task.exists?).to be true
  end

  it 'reports absence when the lookup fails' do
    expect(task).to receive(:shell_out).and_return(live_lookup(false))
    expect(task.exists?).to be false
  end

  it 'names what it found under verbose' do
    verbose_task = described_class.new(resource_type: 'deployment', name: 'web', namespace: 'specs', verbose: true)
    allow(verbose_task).to receive(:shell_out).and_return(live_lookup(true))
    expect(Matsuri).to receive(:log).with(:info, /deployment\/web already started/)
    expect(verbose_task.exists?).to be true
  end

  it 'returns the live manifest as a parsed hash' do
    expect(task).to receive(:shell_out)
      .with('kubectl --context=dev --namespace=specs get deployment/web -o json', { echo_level: :debug, no_stdout: true })
      .and_return(live_lookup(true, stdout: '{"kind":"Deployment"}'))
    expect(task.manifest).to eq('kind' => 'Deployment')
  end

  it 'returns nil for the manifest when not on the cluster' do
    expect(task).to receive(:shell_out).and_return(live_lookup(false))
    expect(task.manifest).to be_nil
  end
end
