# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Apply do
  let(:task) do
    described_class.new(input: "kind: Pod\n", namespace: 'specs', description: 'pod/sidecar')
  end

  it 'applies the payload with context and namespace injected' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs apply -f -', { input: "kind: Pod\n" })
    task.run!
  end
end
