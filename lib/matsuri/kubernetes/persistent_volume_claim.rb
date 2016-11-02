require 'active_support/core_ext/hash/compact'

module Matsuri
  module Kubernetes
    # Kubernetes Persistent Volume Claim
    # http://kubernetes.io/docs/user-guide/persistent-volumes/#persistentvolumeclaims
    class PersistentVolumeClaim < Matsuri::Kubernetes::Base
      let(:kind)                { 'PersistentVolumeClaim' }
      let(:default_annotations) { { 'volume.beta.kubernetes.io/storage-class' => storage_class } } # http://kubernetes.io/docs/user-guide/persistent-volumes/

      let(:spec) do
        {
          resources:   resources,
          accessModes: Array(access_modes),
          selector:    selector
        }
      end

      let(:resources)    { { limits: limits, requests: requests }.compact }
      let(:limits)       { nil }
      let(:requests)     { { storage: storage_size } }
      let(:storage_size) { fail NotImplementedError, 'Must define let(:storage_size)' }
      let(:selector)     { { matchLabels: match_labels, matchExpressions: match_expressions }.compact }

      let(:match_labels)      { fail NotImplementedError, 'Must define let(:match_labels)' }
      let(:match_expressions) { nil }

      class << self
        # Registry helpers
        def load_path
          Matsuri::Config.persistent_volume_claims_path
        end

        def definition_module_name
          'PersistentVolumeClaims'
        end
      end
    end
  end
end
