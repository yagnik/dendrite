module Dendrite
  module Generators
    class Synapse < Base
      attr_reader :instance_id, :instance_ip, :service_conf_dir, :services

      Service = Struct.new(:service) do
        def name
          service.name
        end

        def to_h
          discovery_config.merge(haproxy_config).merge(default_servers_config)
        end

        def discovery_config
          {
            discovery: {
              method: 'zookeeper',
              hosts: [],
              path: "/smartstack/services/#{service.name}/instances"
            }
          }
        end

        def haproxy_config
          {
            haproxy: {
              port: service.advertised_port
            }
          }
        end

        def default_servers_config
          {}
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
          haproxy: global_haproxy_config,
          file_output: {
            output_directory: '/tmp/synapse.config'
          }
        }.merge({services: service_list})
      end

      def global_haproxy_config
        {
          reload_command: 'foo',
          config_file_path: 'bar',
          do_writes: true,
          do_reloads: true,
          do_socket: false,
          bind_address: '0.0.0.0',
          state_file_path: '/tmp/synapse_state'
        }
      end
    end
  end
end
