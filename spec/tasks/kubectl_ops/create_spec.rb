# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Create do
  def task(opts = {})
    described_class.new({ input: "kind: Pod\n", namespace: 'specs', description: 'pod/sidecar' }.merge(opts))
  end

  it 'creates the payload, seeding last-applied-configuration' do
    t = task
    expect(t).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs create --save-config=true -f -', { input: "kind: Pod\n" })
    t.run!
  end

  it 'can opt out of save-config for replace-delivered resources' do
    t = task(save_config: false)
    expect(t).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs create --save-config=false -f -', { input: "kind: Pod\n" })
    t.run!
  end
end
