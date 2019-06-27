module Matsuri
  module DSL
    module Cluster
      # Cluster resources here in Matsuri are a bit different as the are meant to
      # be driven by the cluster dsl
      class ClusterRole < Matsuri::DSL::Cluster::Role
        attr_accessor :aggregation_selectors

        let(:kind)        { 'ClusterRole' }

        let(:manifest) do
          {
            apiVersion:  api_version,
            kind:        kind,
            metadata:    final_metadata,
            aggregationRule: { clusterRoleSelectors: aggregation_selectors }
          }
        end

        # Cluster Roles are not namespaced. Override from MetadataDsl concern
        let(:metadata) { { name: name, labels: final_labels, annotations: final_annotations } }

        def initialize(options = {}, &block)
          self.aggregation_selectors = []
          super
        end

        ### DSL Helper

        # Match helper for creating selectors for aggregatied cluster roles
        # Examples:
        #   match 'example.com/aggregate-to-monitor' => true
        #   match 'example.com/aggregate-to-monitor', 
        def match(*args)
          case
          when args[0].is_a?(Hash)        then match_labels(args[0])
          when args.length.between?(2, 3) then match_expression(*args)
          else
            fail ArgumentError, <<-EOT
              match helper requires one of the following formats

              match key: value, key: value
              match key, operator
              match key, operator, value

              Arguments received: #{args.inspect}
              EOT
          end
        end

        def match_labels(selectors = {})
          aggregation_selectors << selectors
        end

        def match_expression(key, operator, value = nil)
          aggregation_selectors << { key: key, operator: map_match_operator(operator), value: value }.compact
        end

        def map_match_operator(operator)
          case operator
          when 'In', 'in', :in                                   then 'In'
          when 'NotIn', 'not_in', :not_in                        then 'NotIn'
          when 'Exists', 'exists', :exists                       then 'Exists'
          when 'DoesNotExist', 'does_not_exist', :does_not_exist then 'DoesNotExist'
          else
            fail ArgumentError, "Invalid match expression operator: #{operator}"
          end
        end
      end
    end
  end
end

