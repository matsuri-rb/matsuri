# frozen_string_literal: true

cluster_role 'traefik-ingress-controller' do
  resources %w[services endpoints secrets], verbs: %w[get list watch]
  bind_to 'traefik-ingress-controller', kind: :service_account, namespace: 'kube-system'
end

aggregated_cluster_role 'platform-admin' do
  match 'example.com/aggregate-to-admin' => 'true'
  match 'example.com/aggregate', :exists
end

namespace 'default' do
  role 'deployer' do
    resources :deployments, verbs: %w[patch update]
    bind_to 'deployer', kind: :service_account
  end
end

service_account 'ci-runner', namespace: 'default'

service_account 'image-puller', namespace: 'default' do
  automount_token false
  image_pull_secret 'regcred'
  secret 'deploy-key'
end
