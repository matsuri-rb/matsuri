# frozen_string_literal: true

# A job workload: Kubernetes rejects restartPolicy Always in Job pod
# templates, so the pod declares OnFailure itself.
Matsuri.define :pod, 'report' do
  let(:container)      { { name: 'report', image: 'report:latest' } }
  let(:volumes)        { [] }
  let(:restart_policy) { 'OnFailure' }
end
