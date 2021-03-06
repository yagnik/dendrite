module Dendrite
  module Generators
    class Base
      attr_reader :graph, :services

      def initialize(graph:, service_names:)
        @graph = graph
        @services = graph.services
                         .select { |service_name, service| service_names.include?(service_name) }
                         .collect { |_, service| service }
      end

      def to_h
        raise NotImplementedError
      end

      def to_yaml
        self.to_h.deep_stringify_keys.to_yaml
      end

      def to_json
        self.to_h.to_json
      end
    end
  end
end
