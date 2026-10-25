# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'cluster DSL manifests' do
  let(:task)              { Matsuri::Tasks::Cluster.new }
  let(:rbac_manifests)    { task.all_rbac_manifests }
  let(:cluster_manifests) { task.all_cluster_manifests }
  let(:by_kind_and_name) do
    rbac_manifests.group_by { |m| [m[:kind], m[:metadata][:name]] }
  end

  it 'renders the five RBAC manifests from the fixture' do
    kinds = rbac_manifests.map { |m| m[:kind] }
    expect(kinds).to contain_exactly(
      'ClusterRole', 'ClusterRoleBinding', 'ClusterRole', 'Role', 'RoleBinding'
    )
  end

  it 'renders a regular cluster role with rules' do
    role = by_kind_and_name[%w[ClusterRole traefik-ingress-controller]].first

    expect(role[:metadata].key?(:namespace)).to be false
    expect(role[:rules]).to eq [
      { 'apiGroups' => [''], 'resources' => %w[services endpoints secrets], 'verbs' => %w[get list watch] }
    ]
  end

  it 'renders the aggregated cluster role with selectors and no rules' do
    role = by_kind_and_name[%w[ClusterRole platform-admin]].first

    expect(role[:aggregationRule]).to eq(
      clusterRoleSelectors: [
        { 'example.com/aggregate-to-admin' => 'true' },
        { key: 'example.com/aggregate', operator: 'Exists' }
      ]
    )
    expect(role.key?(:rules)).to be false
  end

  it 'suppresses bindings with no subjects' do
    expect(by_kind_and_name[%w[ClusterRoleBinding platform-admin]]).to be_nil
  end

  it 'renders camelCase apiGroup on binding subjects' do
    binding = by_kind_and_name[%w[ClusterRoleBinding traefik-ingress-controller]].first

    expect(binding[:subjects]).to eq [
      { name: 'traefik-ingress-controller', kind: 'ServiceAccount',
        namespace: 'kube-system', apiGroup: '' }
    ]
  end

  it 'scopes roles declared inside a namespace block' do
    role = by_kind_and_name[%w[Role deployer]].first
    binding = by_kind_and_name[%w[RoleBinding deployer]].first

    expect(role[:metadata][:namespace]).to eq 'default'
    expect(binding[:subjects]).to eq [
      { name: 'deployer', kind: 'ServiceAccount', namespace: 'default', apiGroup: '' }
    ]
  end

  it 'renders the service account as a cluster manifest' do
    sa = cluster_manifests.find { |m| m[:kind] == 'ServiceAccount' && m[:metadata][:name] == 'ci-runner' }

    expect(sa[:metadata][:namespace]).to eq 'default'
  end

  it 'accumulates image pull secrets, secrets, and automount through the helpers' do
    sa = cluster_manifests.find { |m| m[:kind] == 'ServiceAccount' && m[:metadata][:name] == 'image-puller' }

    expect(sa[:automountServiceAccountToken]).to be false
    expect(sa[:imagePullSecrets]).to eq [{ name: 'regcred' }]
    expect(sa[:secrets]).to eq [{ name: 'deploy-key' }]
  end
end
