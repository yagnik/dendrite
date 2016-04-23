module Dendrite
  module Generators
    class Base
      attr_reader :graph

      def initialize(graph:)
        @graph = graph
      end

      def to_h
        raise NotImplementedError
      end

      def to_yaml
        self.to_h.to_yaml
      end

      def to_json
        self.to_h.to_json
      end
    end
  end
end
