# One podspec shared by every bulkhead. Identity is two axes passed by
# the owning deployment: app_role (web, worker) names the workload,
# resource_class (standard, streams, general) names the capacity class.
# The class table supplies scalar defaults; each scalar stays its own
# override point, so a deployment can name a class and still tune one
# leaf.
Matsuri.define :pod, 'app' do
  let(:app_role)       { options[:app_role] }
  let(:resource_class) { options[:resource_class] || 'standard' }

  let(:labels) { { 'app_role' => app_role, 'resource_class' => resource_class }.compact }

  let(:resource_classes) do
    {
      'standard' => { cpu_request: '250m', mem_request: '256Mi', mem_limit: '512Mi' },
      'streams'  => { cpu_request: '1',    mem_request: '1Gi',   mem_limit: '2Gi'   },
      'general'  => { cpu_request: '500m', mem_request: '512Mi', mem_limit: '1Gi'   }
    }
  end
  let(:resource_class_defaults) { resource_classes.fetch(resource_class) }

  let(:cpu_request) { options[:cpu_request] || resource_class_defaults[:cpu_request] }
  let(:mem_request) { options[:mem_request] || resource_class_defaults[:mem_request] }
  let(:cpu_limit)   { options[:cpu_limit]   || resource_class_defaults[:cpu_limit] }
  let(:mem_limit)   { options[:mem_limit]   || resource_class_defaults[:mem_limit] }

  let(:volumes) { [] }

  let(:container) do
    {
      name:      'app',
      image:     "app:#{image_tag}",
      resources: resources
    }
  end
end
