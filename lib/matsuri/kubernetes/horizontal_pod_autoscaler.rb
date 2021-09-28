require 'active_support/core_ext/hash/compact'
module Matsuri
  module Kubernetes
    class HorizontalPodAutoscaler < Matsuri::Kubernetes::Base
      # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#horizontalpodautoscalerspec-v2beta2-autoscaling
      # https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
      # https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
      let(:api_version) { 'autoscaling/v2beta2' }    # K8S 1.16+
      let(:kind)        { 'HorizontalPodAutoscaler' }

      let(:spec) do
        {
          scaleTargetRef: scale_target_ref,
          minReplicas:    min_replicas,
          maxReplicas:    max_replicas,
          metrics:        metrics,
          behavior:       behavior
        }
      end

      let(:scale_target_ref) { fail NotImplementedError, 'Must define let(:scale_target_ref)' }
      let(:min_replicas)     { 1 }
      let(:max_replicas)     { nil }

      let(:metrics)          { [metric] }
      let(:metric)           { fail NotIm0lementedError, 'Must define let(:default_metric)' }

      let(:behavior)            { { scaleUp: scale_up_behavior, scaleDown: scale_down_behavior }.compact }
      let(:scale_down_behavior) { nil }
      let(:scale_up_behavior)   { nil }

      ### Helpers

      # Extracts the version, name, and kind from a Matsuri ref
      # Example: resource_ref_from_def(deployment_spec('my-deployment'))
      def resource_ref_from_def(resource_def)
        {
          apiVersion: resource_def.api_version,
          kind:       resource_def.kind,
          name:       resource_def.name
        }
      end

      def resource_metric_source(name, metric_target)
        {
          type: 'Resource',
          resource: {
            name: name,
            target: metric_target
          }
        }
      end

      def pod_metric_source(name, metric_target, metric_selector: nil)
        {
          type: 'Pods',
          pods: {
            metric: { name: name, selector: metric_selector }.compact,
            target: metric_target
          }
        }
      end

      def object_metric_source(name, metric_target, metric_selector: nil, described_object:)
        {
          type: 'Pods',
          pods: {
            metric: { name: name, selector: metric_selector }.compact,
            describedObject: described_object,
            target: metric_target
          }
        }
      end

      def utilization_metric_target(target)
        { type: 'Utilization', averageUtilization: target }
      end

      def average_value_matric_target(target)
        { type: 'AverageValue', averageValue: target }
      end

      def value_metric_target(target)
        { type: 'Value', value: target }
      end

      def hpa_scaling_rule(policies:, select_policy: 'MaxPolicySelect', stabilization_window_seconds: nil)
        {
          policies: policies,
          selectPolicy: select_policy,
          stabilizationWindowSeconds: stabilization_window_seconds
        }.compact
      end

      def hpa_scaling_policy(type:, value:, period_seconds:)
        {
          type:          type,
          value:         value,
          periodSeconds: period_seconds
        }
      end

      class << self
        def load_path
          Matsuri::Config.horizontal_pod_autoscalers_path
        end

        def definition_module_name
          'HorizontalPodAutoscalers'
        end
      end
    end
  end
end

