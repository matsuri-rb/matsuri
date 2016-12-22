
module Matsuri
  module Kubernetes
    # Kubernetes Persistent Volume
    # http://kubernetes.io/docs/user-guide/persistent-volumes/#storageclasses
    # No official API definition found
    class StorageClass < Matsuri::Kubernetes::Base
      let(:kind)        { 'StorageClass' }
      let(:api_version) { 'storage.k8s.io/v1beta1' }
      let(:provisioner) { fail NotImplementedError, 'Must define let(:provisioner). Example: let(:provisoner) { gce_pd }' }

      let(:gce_pd)      { 'kubernetes.io/gce-pd' }
      let(:aws_ebs)     { 'kubernetes.io/aws-ebs' }

      let(:parameters)  { fail NotImplementedError, 'Must define let(:parameters)' }

      let(:manifest) do
        {
          apiVersion:  api_version,
          kind:        kind,
          metadata:    final_metadata,
          provisioner: provisioner,
          parameters:  parameters
        }
      end

      class << self
        def load_path
          Matsuri::Config.storage_classes_path
        end

        def definition_module_name
          'StorageClasses'
        end
      end
    end
  end
end
