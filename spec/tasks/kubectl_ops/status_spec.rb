# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::Status do
  let(:task) do
    described_class.new(resource_type: 'deployment', name: 'web', namespace: 'specs')
  end

  it 'displays live state by type/name' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs get deployment/web -o wide', {})
    task.run!
  end
end
