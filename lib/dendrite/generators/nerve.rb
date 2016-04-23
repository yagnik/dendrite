module Dendrite
  module Generators
    class Nerve < Base
      attr_reader :instance_id, :instance_ip, :service_conf_dir, :services

      Service = Struct.new(:service) do
        def name
          service.name
        end

        def to_h
          {
            host: instance_ip,
            port: service.listening_port,
          }.merge(zookeeper_config).merge(check_config)
        end

        def zookeeper_config
          {
            reporter_type: 'zookeeper',
            zk_hosts: [],
            zk_path: "/smartstack/services/#{service.name}/instances"
          }
        end

        def check_config
          {}
        end

        def instance_ip
          '192.168.1.1'
        end
      end

      def initialize(graph:, service_names:)
        super(graph: graph)
        @services = graph.services
                        .select { |service_name, service| service_names.include?(service_name) }
                        .collect { |service_name, service| Service.new(service)}
      end

      def to_h
        service_list = services.inject({}) do |hash, service|
          hash[service.name] = service.to_h
          hash
        end

        {
          instance_id: instance_id,
          service_conf_dir: service_conf_dir
        }.merge({services: service_list})
      end
    end
  end
end
