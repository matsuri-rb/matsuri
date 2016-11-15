module Matsuri
  module Concerns
    module Scalable
      def scale!(replicas, opt={})
        Matsuri.log :info, "Scaling #{resource_type}/#{name} to #{replicas}".color(:yellow).bright
        kubectl! "--namespace=#{namespace} scale --replicas=#{replicas} #{resource_type}/#{name}"
      end
    end
  end
end