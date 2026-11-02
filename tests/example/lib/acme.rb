# Example local library
# This is the entry point for local concerns and customizations
# for Matsuri. You can also use this register your own
# custom resources, such as Istio VirtualService, or
# CloudNativePG resources

module Acme
  module Pods
    # It is better for teams to standardize on healthchecks. These would
    # be promises (promise theory) that workloads make. The use of let()
    # allows for overrides for specific workloads
    autoload :Healthcheck,  'acme/pods/healthcheck'
    autoload :CACerts,      'acme/pods/cacerts'

  end

  module Nodes
    # Scheduling
    autoload :Dedicated,     'acme/nodes/dedicated'
    autoload :Preemptible,   'acme/nodes/preemptible'
    autoload :RequiredCores, 'acme/nodes/required_cores'
    autoload :ResourceClass, 'acme/nodes/resource_class'
  end

end

