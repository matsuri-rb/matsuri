# frozen_string_literal: true

require 'spec_helper'

# Payloads declare in persistence normal form: emptiness never rides a
# declaration, so a create's echo equals the declaration and ceding a
# field is structurally the same as saying nothing. The conflict this
# kills: an atomic struct (.spec.selector) carrying an empty member
# diverges from the server's normalized persisted value, and the seeding
# protocol's equal-values co-ownership turns into a loud conflict.
RSpec.describe 'prune empty presenter' do
  include Matsuri::Presenters::Helpers

  let(:workload) do
    Map.new(kind: 'Deployment',
            metadata: { name: 'app', annotations: {} },
            spec: {
              replicas: nil,
              selector: { matchLabels: { app: 'web' }, matchExpressions: [] },
              template: { spec: {
                containers:   [{ name: 'app', env: [] }],
                nodeSelector: {},
                tolerations:  [],
                volumes:      []
              } }
            })
  end

  it 'prunes nils and empty collections, bottom-up' do
    pruned = prune_empty.call(workload)
    expect(pruned.get(:spec, :selector).keys).to eq ['matchLabels']
    expect(pruned.get(:spec).key?(:replicas)).to be false
    expect(pruned.get(:spec, :template, :spec).keys).to eq ['containers']
    expect(pruned.get(:metadata).keys).to eq ['name']
  end

  it 'prunes parents that pruning emptied' do
    manifest = Map.new(kind: 'Pod', spec: { affinity: { nodeAffinity: {} } })
    expect(prune_empty.call(manifest).key?(:spec)).to be false
  end

  it 'keeps empty strings: "" is a value, not emptiness' do
    manifest = Map.new(spec: { storageClassName: '' })
    expect(prune_empty.call(manifest).get(:spec, :storageClassName)).to eq ''
  end

  it 'never drops array elements, but prunes their interiors' do
    pruned = prune_empty.call(workload)
    containers = pruned.get(:spec, :template, :spec, :containers)
    expect(containers.length).to eq 1
    expect(containers[0].key?(:env)).to be false
  end

  it 'preserves excepted paths even when empty' do
    pruned = prune_empty(except: [%i[spec selector matchExpressions]]).call(workload)
    expect(pruned.get(:spec, :selector, :matchExpressions)).to eq []
  end

  it 'ships with no exceptions' do
    bare = Class.new(Matsuri::Presenter) { include Matsuri::Presenters::PruneEmpty }
    expect(bare.new.exceptions).to eq []
  end
end
