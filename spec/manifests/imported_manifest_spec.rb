# frozen_string_literal: true

require 'spec_helper'

# ImportManifest keeps the import surface; the transform vocabulary comes
# from the dialect. The env-entry example pins the path that used to be
# dead by construction: set_env -> update_kv -> expand_env was unreachable
# from an imported manifest before the strata, as was append_node_affinity.
RSpec.describe 'imported manifests on the transform strata' do
  let(:imported) { Matsuri::Registry.imported_manifest('vendor-app').new }
  let(:docs)     { imported.manifest_for_export }

  it 'loads the definition and extracts the full stream' do
    expect(docs.map { |d| d['kind'] }).to eq %w[Deployment Service]
  end

  it 'customizes through the dialect: set_env reaches an imported pod spec' do
    env = docs.first['spec']['template']['spec']['containers'][0]['env']
    expect(env).to include('name' => 'IMPORTED', 'value' => 'true')
    expect(env.first['name']).to eq 'LOG_LEVEL'
  end

  it 'reaches the node-affinity helpers' do
    scheduling = Map.new(affinity: { nodeAffinity: { requiredDuringSchedulingIgnoredDuringExecution: { nodeSelectorTerms: [] } } })
    imported.append_node_affinity(scheduling, matchExpressions: [{ key: 'zone', operator: 'In', values: ['a'] }])
    expect(scheduling.get(*Matsuri::Transform::Kubernetes::NODE_SELECTOR_TERMS_PATH).length).to eq 1
  end

  it 'addresses manifests within the stream by criteria' do
    stream = imported.imported_manifests

    found = imported.lookup_manifests(stream, kind: 'Service', name: 'vendor-app')
    expect(found.length).to eq 1

    remaining = imported.without_manifest(stream, kind: 'Service', name: 'vendor-app')
    expect(remaining.map { |d| d['kind'] }).to eq ['Deployment']
  end

  it 'exports the customized stream as concatenated YAML documents' do
    expect(imported.to_yaml.scan(/^---$/).length).to eq 2
    expect(imported.to_yaml).to match(/name: IMPORTED/)
  end

  it 'delivers the same payload the export promises' do
    expect(Matsuri::Tasks::KubectlOps.apply_payload(imported, {})).to eq imported.applied_to_yaml
  end
end
