module Dendrite
  module Generators
    class Nerve < Base
      Service = Struct.new(:service) do
        def discovery
        end

        def haproxy
        end

        def default_servers
        end
      end

      def build
      end

      def file_output
      end

      def haproxy
        default_config[:haproxy]
      end

      def discovery(path)
        default_config[:discovery].merge({
          method: 'zookeeper',
          path: path
        })
      end

      def default_config
      end
    end
  end
end
