require 'active_support/concern'

module Matsuri
  module Concerns
    module RbacRulesDsl
      extend ActiveSupport::Concern

      included do
        attribute_accessor :rules
      end

      def initialize_rbac_rules_dsl
        self.rules = []
      end

      def rule(api_groups: '', urls: nil, resources: nil, names: nil, verbs: nil)
        rules << {
          'apiGroups'       => api_groups,
          'nonResourceURLs' => urls,
          'resourceNames'   => names,
          'resources'       => resources,
          'verbs'           => verbs
        }.compact.map(&method(:normalize_string_array)).to_h
      end

      def resources(resources, names: nil, verbs: nil, api_groups: nil)
        rule api_groups: api_groups, resources: resources, names: names, verbs: verbs
      end

      def normalize_string_array(x)
        Array(x).map(&:to_s)
      end
    end
  end
end
