# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Diff do
  let(:task) do
    described_class.new(input: "kind: Deployment\n", namespace: 'specs', description: 'deployment/web')
  end

  def diff_run(exitstatus)
    instance_double(Mixlib::ShellOut, exitstatus: exitstatus, stdout: '', stderr: '')
  end

  it 'dry-runs the payload through the apiserver' do
    expect(task).to receive(:shell_out)
      .with('kubectl --context=dev --namespace=specs diff -f -', { input: "kind: Deployment\n" })
      .and_return(diff_run(0))
    task.run!
  end

  it 'dry-runs server-side under the same manager apply would deliver with' do
    server_side = described_class.new(input: "kind: Deployment\n", namespace: 'specs',
                                      description: 'deployment/web',
                                      server_side: true, field_manager: 'matsuri')
    expect(server_side).to receive(:shell_out)
      .with('kubectl --context=dev --namespace=specs diff --server-side --field-manager=matsuri -f -',
            { input: "kind: Deployment\n" })
      .and_return(diff_run(0))
    server_side.run!
  end

  it 'treats differences-found (exit 1) as success' do
    expect(task).to receive(:shell_out).and_return(diff_run(1))
    expect { task.run! }.not_to raise_error
  end

  it 'is fatal above exit 1' do
    expect(task).to receive(:shell_out).and_return(diff_run(2))
    expect { task.run! }.to raise_error(SystemExit)
  end
end
