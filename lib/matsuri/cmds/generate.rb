
module Matsuri
  module Cmds
    class Generate < Thor
      include Matsuri::Cmd

      def self.generate_cmd_for(resource_name)
        define_method(resource_name) do |name = :not_specified|
          generate_resource { Matsuri::Registry.fetch_or_load(resource_name, name).new }
        end
      end

      private

      def generate_resource
        with_config do |opt|
          resource = yield
          resource.generate_template!
        end
      end
    end
  end
end
