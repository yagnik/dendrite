module Dendrite
  module Generators
    class Synapse < Base
      def initialize(graph:, service_names:, proxy: false)
        super(graph: graph, service_names: service_names)
        unless proxy
          dep = []
          @services.each do |service|
            service.dependencies.each do |_, dependency|
              dep << dependency.service
            end
          end
          @services = dep.uniq
        end
        @services.group_by { |service| service.loadbalancer_port }.each do |port, services|
          if services.length > 1
            raise PortCollision, "Port collission between #{services.collect(&:name).join(',')}"
          end
        end
        @services = @services.collect { |service| ServiceConfig.new(service)}
      end

      def to_h
        service_list = services.inject({}) do |hash, service|
          hash[service.name] = service.to_h
          hash
        end

        {
          haproxy: Dendrite::Config.global_haproxy_config,
          file_output: {
            output_directory: '/tmp/synapse.config'
          }
        }.merge({services: service_list})
      end

      private

      ServiceConfig = Struct.new(:service) do
        extend Forwardable
        def_delegator :service, :name, :name
        def_delegator :service, :component, :component
        def_delegator :service, :organization, :organization

        def to_h
          discovery_config.merge(haproxy_config)
        end

        def discovery_config
          {
            discovery: {
              method: 'zookeeper',
              hosts: Dendrite::Config.zk_hosts,
              path: "/smartstack/services/#{organization}/#{component}/#{service.real_name}/instances"
            }
          }
        end

        def haproxy_config
          {
            haproxy: {
              port: service.loadbalancer_port,
              server_options: 'check inter 2s rise 3 fall 2',
              listen: [
                'mode tcp'
              ]
            }
          }
        end
      end
    end
  end
end
