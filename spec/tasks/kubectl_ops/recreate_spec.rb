# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Recreate do
  let(:ops) { Matsuri::Tasks::KubectlOps }
  let(:delete_task) { instance_double(ops::Delete, run!: true) }
  let(:create_task) { instance_double(ops::Create, run!: true) }

  let(:task) do
    described_class.new(resource_type: 'pod', name: 'sidecar', namespace: 'specs', create: create_task)
  end

  before do
    allow(ops::Delete).to receive(:new).and_return(delete_task)
  end

  it 'deletes, awaits the deletion, then runs the creation task when the object is live' do
    get_task = instance_double(ops::Get)
    allow(ops::Get).to receive(:new).and_return(get_task)
    allow(get_task).to receive(:exists?).and_return(true, false)

    expect(delete_task).to receive(:run!).ordered
    expect(create_task).to receive(:run!).ordered
    task.run!
  end

  it 'runs the creation task directly when nothing is live' do
    allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: false))

    expect(delete_task).not_to receive(:run!)
    expect(create_task).to receive(:run!)
    task.run!
  end
end
