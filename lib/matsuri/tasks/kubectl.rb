module Matsuri
  module Tasks
    class Kubectl
      include Matsuri::Task

      let(:environment)  { Matsuri.environment }
      let(:env_config)   { Matsuri::Platform.send(environment) }
      let(:namespace)    { env_config.namespace || 'default' }
      let(:kube_user)    { env_config.user || kube_context }
      let(:kube_cluster) { env_config.kube_cluster || kube_context }

      # Set up aliases for kubectl. This allows you you to use
      # `kubectl --context=staging` instead of the name given by GKE
      def setup!
        shell_out! "kubectl config set-context #{environment} --cluster=#{kube_cluster} --namespace=#{namespace} --user=#{kube_user}"
      end
    end
  end
end
