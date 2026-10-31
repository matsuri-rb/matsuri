# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::HashDiff do
  let(:resource) { Matsuri::Registry.fetch_or_load(:deployment, 'web').new }
  let(:current)  { JSON.parse(resource.to_json) }

  def task(opts = {})
    described_class.new({ resource: resource }.merge(opts))
  end

  it 'fetches the current manifest and prints the filtered deltas' do
    current['spec']['replicas'] = 99
    expect(Matsuri::Tasks::KubectlOps).to receive(:manifest).with(resource).and_return(current)
    expect { task.run! }.to output(/spec\.replicas/).to_stdout
  end

  it 'routes primary_container to the focused diff' do
    expect(Matsuri::Tasks::KubectlOps).to receive(:manifest).with(resource).and_return(current)
    expect(resource).to receive(:primary_container_diff).with(current).and_return([])
    task(primary_container: true).run!
  end

  it 'is fatal when the resource is not on the cluster' do
    expect(Matsuri::Tasks::KubectlOps).to receive(:manifest).and_return(nil)
    expect(Matsuri).to receive(:log).with(:fatal, 'Cannot fetch current manifest for deployment/web').and_raise(SystemExit)
    expect { task.run! }.to raise_error(SystemExit)
  end
end
