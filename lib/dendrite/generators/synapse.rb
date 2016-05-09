module Dendrite
  module Generators
    class Synapse < Base
      def initialize(graph:, service_names:)
        super
        dep = []
        @services.each do |service|
          service.dependancies.each do |_, dependancy|
            dep << dependancy.service
          end
        end
        @services = dep.uniq
        @services.group_by { |service| service.advertised_port }.each do |port, services|
          if services.length > 1
            raise PortCollission, "Port collission between #{services.collect(&:name).join(',')}"
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
        def_delegator :service, :namespace, :namespace
        def_delegator :service, :organization, :organization

        def to_h
          discovery_config.merge(haproxy_config)
        end

        def discovery_config
          {
            discovery: {
              method: 'zookeeper',
              hosts: Dendrite::Config.zk_hosts,
              path: "/smartstack/services/#{organization}/#{namespace}/#{service.real_name}/instances"
            }
          }
        end

        def haproxy_config
          {
            haproxy: {
              port: service.advertised_port,
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
