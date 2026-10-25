# One podspec shared by every bulkhead. The owning deployment decides
# identity and capacity through lazy options; the pod overrides only the
# granular leaves. Assembly (resources, containers) stays in the base Pod.
Matsuri.define :pod, 'app' do
  let(:app_role) { options[:app_role] }
  let(:labels)   { { 'app_role' => app_role }.compact }

  let(:cpu_request) { options[:cpu_request] || '250m' }
  let(:mem_request) { options[:mem_request] || '256Mi' }
  let(:cpu_limit)   { options[:cpu_limit] }
  let(:mem_limit)   { options[:mem_limit] || '512Mi' }

  let(:volumes) { [] }

  let(:container) do
    {
      name:      'app',
      image:     "app:#{image_tag}",
      resources: resources
    }
  end
end
