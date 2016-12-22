module Matsuri
  module Concerns
    module Scalable
      def scale!(replicas, opt={})
        Matsuri.log :info, "Scaling #{resource_type}/#{name} to #{replicas}".color(:yellow).bright
        kubectl! "scale --replicas=#{replicas} --record=true #{resource_type}/#{name}"
      end
    end
  end
end
