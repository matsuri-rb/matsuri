# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::RolloutStatus do
  let(:task) do
    described_class.new(resource_type: 'deployment', name: 'web', namespace: 'specs')
  end

  it 'watches the rollout by type/name' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs rollout status deployment/web', {})
    task.run!
  end
end
