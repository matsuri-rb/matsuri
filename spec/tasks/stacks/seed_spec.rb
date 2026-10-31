# frozen_string_literal: true

require 'spec_helper'

# The creation protocol for server-side-applied resources; the cluster
# semantics it rests on are pinned by tests/bin/probe-ssa.sh.
RSpec.describe Matsuri::Tasks::Stacks::Seed do
  let(:seeded)   { "kind: Deployment\nspec: seeded\n" }
  let(:declared) { "kind: Deployment\nspec: declared\n" }

  let(:task) do
    described_class.new(seeded: seeded, declared: declared,
                        resource_type: 'deployment', name: 'web', namespace: 'specs',
                        field_manager: 'matsuri')
  end

  let(:get_line) { 'kubectl --context=dev --namespace=specs get deployment/web --show-managed-fields -o json' }

  def live_read(managers)
    fields = managers.map { |manager| { manager: manager } }
    instance_double(Mixlib::ShellOut, stdout: { metadata: { managedFields: fields } }.to_json)
  end

  def patch_result(success, stderr: '')
    instance_double(Mixlib::ShellOut,
                    status: instance_double(Process::Status, success?: success),
                    stderr: stderr)
  end

  def removal_patch(idx)
    "[{\"op\":\"test\",\"path\":\"/metadata/managedFields/#{idx}/manager\",\"value\":\"matsuri-seed\"}," \
      "{\"op\":\"remove\",\"path\":\"/metadata/managedFields/#{idx}\"}]"
  end

  def patch_line(idx)
    "kubectl --context=dev --namespace=specs patch deployment/web --type=json -p '#{removal_patch(idx)}'"
  end

  it 'creates seeded as the seed owner, applies declared as the field manager, then removes the seed owner entry' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs create --field-manager=matsuri-seed -f -', { input: seeded })
      .ordered

    ssa = instance_double(Matsuri::Tasks::KubectlOps::ServerSideApply, run!: true)
    expect(Matsuri::Tasks::KubectlOps::ServerSideApply).to receive(:new)
      .with(input: declared, namespace: 'specs', description: 'deployment/web', field_manager: 'matsuri')
      .ordered.and_return(ssa)

    expect(task).to receive(:shell_out!)
      .with(get_line, { echo_level: :debug, no_stdout: true })
      .ordered
      .and_return(live_read(%w[matsuri matsuri-seed kube-controller-manager]))
    expect(task).to receive(:shell_out)
      .with(patch_line(1), { no_stdout: true })
      .ordered.and_return(patch_result(true))

    task.run!
  end

  it 'rereads the index and retries when a concurrent write moves the entry' do
    expect(task).to receive(:shell_out!).with(get_line, anything)
      .and_return(live_read(%w[matsuri-seed matsuri]), live_read(%w[matsuri matsuri-seed]))
    expect(task).to receive(:shell_out).with(patch_line(0), anything).and_return(patch_result(false))
    expect(task).to receive(:shell_out).with(patch_line(1), anything).and_return(patch_result(true))
    task.remove_seed_owner!
  end

  it 'is fatal when the entry keeps moving' do
    allow(task).to receive(:shell_out!).with(get_line, anything).and_return(live_read(%w[matsuri-seed]))
    allow(task).to receive(:shell_out).and_return(patch_result(false, stderr: 'conflict'))
    expect(Matsuri).to receive(:log).with(:fatal, /could not remove matsuri-seed after 3 attempts/).and_raise(SystemExit)
    expect { task.remove_seed_owner! }.to raise_error(SystemExit)
  end

  it 'is fatal when no seed owner entry exists' do
    allow(task).to receive(:shell_out!).with(get_line, anything).and_return(live_read(%w[matsuri]))
    expect(Matsuri).to receive(:log).with(:fatal, /no managedFields entry for matsuri-seed/).and_raise(SystemExit)
    expect { task.remove_seed_owner! }.to raise_error(SystemExit)
  end
end
