module Matsuri
  module Concerns
    module Awaiting
      def awaiting!(msg, timeout: 500, interval: 10)
        Matsuri.log :info, "Waiting for #{msg}: "
        response = nil
        # Ignore timeout for now
        # Timeout::timeout(timeout) do
          loop do
            response = yield
            break if response
            sleep interval
            print '.'
          end
        #end

        Matsuri.log :info, ' Done.'
        return response
      end
    end
  end
end
