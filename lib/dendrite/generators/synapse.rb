module Dendrite
  module Generators
    class Synapse < Base
      def initialize(graph:, service_names:)
        super
        dep = {}
        @services.each do |service_name, service|
          service.dependancies.each do |dependancy_name, dependancy|
            dep[dependancy_name] = dependancy.service
          end
        end
        @services = dep
        @services = @services.collect { |service_name, service| ServiceConfig.new(service)}
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
        def_delegator :service, :namespace, :namespace

        def to_h
          discovery_config.merge(haproxy_config)
        end

        def discovery_config
          {
            discovery: {
              method: 'zookeeper',
              zk_hosts: Dendrite::Config.zk_hosts,
              zk_path: "/smartstack/services/#{namespace}/#{name}/instances"
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
