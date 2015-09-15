module Matsuri
  module Cmds
    class Pod < Thor
      desc 'build', 'build a pod'
      def build(pod_name)
        Matsuri::Tasks::Pod.new(final_options(pod_name: pod_name)).build!
      end

      desc 'list', 'list all pod definitions'
      def list
        Matsuri::Tasks::Pod.new(final_options).list!
      end

      private
      def final_options(opts = {})
        options.merge(parent_options).merge(opts)
      end
    end
  end
end
