module Dendrite
  module Generators
    class Synapse < Base
      def initialize(graph:, service_names:, proxy: false, environment: :dev)
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
        @services = @services.collect { |service| ServiceConfig.new(service, environment)}
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

      ServiceConfig = Struct.new(:service, :environment) do
        extend Forwardable
        def_delegator :service, :name, :name
        def_delegator :service, :component, :component
        def_delegator :service, :organization, :organization
        def_delegator :service, :default_servers, :default_servers

        def to_h
          discovery_config.merge(haproxy_config)
                          .merge(default_servers_config)
        end

        def default_servers_config
          servers = default_servers[environment]
          if servers
            {
              default_servers: servers.enum_for(:each_with_index).collect do |server, i|
                data = server.to_h.merge({
                  name: "default_#{name}_#{i}"
                })
                data.delete(:environment)
                data
              end
            }
          else
            {}
          end
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
              bind_address: '127.0.0.1',
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
