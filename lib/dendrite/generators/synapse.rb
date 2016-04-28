module Dendrite
  module Generators
    class Synapse < Base
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

      ServiceConfigs = Struct.new(:service) do
        delegate :name, service

        def to_h
          discovery_config.merge(haproxy_config)
        end

        def discovery_config
          {
            discovery: {
              method: 'zookeeper',
              zk_hosts: Dendrite::Config.zk_hosts,
              zk_path: "/smartstack/services/#{service.namespace}/#{service.name}/instances"
            }
          }
        end

        def haproxy_config
          {
            haproxy: {
              port: service.advertised_port,
              server_options: 'check inter 2s rise 3 fall 2',
              listen: [
                'mode http'
              ]
            }
          }
        end
      end
    end
  end
end
