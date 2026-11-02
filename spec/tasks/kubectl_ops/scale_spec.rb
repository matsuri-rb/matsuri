# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Scale do
  let(:task) do
    described_class.new(resource_type: 'deployment', name: 'web', namespace: 'specs', replicas: 3)
  end

  it 'scales by type/name' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs scale --replicas=3 deployment/web', {})
    task.run!
  end
end
