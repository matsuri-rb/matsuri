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
    expect(resource).to receive(:primary_container_diff).with(current, desired: kind_of(Hash)).and_return([])
    task(primary_container: true).run!
  end

  it 'is fatal when the resource is not on the cluster' do
    expect(Matsuri::Tasks::KubectlOps).to receive(:manifest).and_return(nil)
    expect(Matsuri).to receive(:log).with(:fatal, 'Cannot fetch current manifest for deployment/web').and_raise(SystemExit)
    expect { task.run! }.to raise_error(SystemExit)
  end

  describe 'the presented declaration as the comparison basis' do
    let(:pinned) do
      pin = Matsuri::Transform::Callable.new(label: 'pin-replicas') do |m|
        m.set([:spec, :replicas], 7)
      end
      Matsuri.define(:deployment, 'web-pinned', inherits: 'web') do
        present :on_apply, pin
      end.new
    end

    it 'reads drift against what apply would send, not the raw declaration' do
      live = JSON.parse(pinned.to_json)
      live['spec']['replicas'] = 7

      allow(Matsuri::Tasks::KubectlOps).to receive(:manifest).and_return(live)
      expect { described_class.new(resource: pinned).run! }
        .not_to output(/spec\.replicas/).to_stdout
    end

    it 'still reports drift the pipeline does not account for' do
      live = JSON.parse(pinned.to_json)
      live['spec']['replicas'] = 99

      allow(Matsuri::Tasks::KubectlOps).to receive(:manifest).and_return(live)
      expect { described_class.new(resource: pinned).run! }
        .to output(/spec\.replicas/).to_stdout
    end

    it 'bases the comparison on the applied manifest, the payload apply sends' do
      restricted = Matsuri.define(:deployment, 'web-restricted', inherits: 'web') do
        let(:applied_manifest) { { apiVersion: api_version, kind: kind, metadata: final_metadata } }
      end.new

      desired = described_class.new(resource: restricted).desired_manifest
      expect(desired).to eq JSON.parse(restricted.applied_to_json)
      expect(desired).not_to have_key('spec')
    end
  end
end
