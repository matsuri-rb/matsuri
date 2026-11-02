# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Replace do
  let(:task) do
    described_class.new(input: "kind: ConfigMap\n", namespace: 'specs', description: 'configmap/settings')
  end

  it 'replaces the live object with the payload' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs replace -f -', { input: "kind: ConfigMap\n" })
    task.run!
  end
end
