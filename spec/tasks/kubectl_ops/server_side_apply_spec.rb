# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::KubectlOps::ServerSideApply do
  let(:task) do
    described_class.new(input: "kind: Deployment\n", namespace: 'specs',
                        description: 'deployment/web', field_manager: 'matsuri')
  end

  it 'applies server-side under the field manager, never forcing conflicts' do
    expect(task).to receive(:shell_out!)
      .with('kubectl --context=dev --namespace=specs apply --server-side --field-manager=matsuri -f -',
            { input: "kind: Deployment\n" })
    task.run!
  end
end
