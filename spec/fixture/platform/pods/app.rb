# One podspec shared by every bulkhead. The owning deployment decides
# identity and capacity through lazy options; the pod only declares the
# defaults.
Matsuri.define :pod, 'app' do
  let(:app_role)          { options[:app_role] }
  let(:resource_requests) { options[:requests] || { cpu: '250m', memory: '256Mi' } }
  let(:resource_limits)   { options[:limits]   || { memory: '512Mi' } }

  let(:labels) { { 'app_role' => app_role }.compact }

  let(:spec) do
    {
      containers: [
        {
          name:      'app',
          image:     "app:#{image_tag}",
          resources: { requests: resource_requests, limits: resource_limits }
        }
      ]
    }
  end
end
