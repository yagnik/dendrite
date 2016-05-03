module Dendrite
  module Generators
    class Nerve < Base

      def initialize(graph:, service_names:)
        super
        @services = @services.collect { |service| ServiceConfig.new(service)}
      end

      def to_h
        service_list = services.inject({}) do |hash, service|
          hash[service.name] = service.to_h
          hash
        end

        {
          instance_id: Dendrite::Config.instance
        }.merge({services: service_list})
      end

      ServiceConfig = Struct.new(:service) do
        extend Forwardable
        def_delegator :service, :name, :name
        def_delegator :service, :namespace, :namespace
        def_delegator :service, :organization, :organization

        def to_h
          {
            host: Dendrite::Config.public_ip,
            port: service.listening_port,
            labels: {
              dc: Dendrite::Config.dc,
              env: Dendrite::Config.env
            }
          }.merge(zookeeper_config)
        end

        def zookeeper_config
          {
            reporter_type: 'zookeeper',
            zk_hosts: Dendrite::Config.zk_hosts,
            zk_path: "/smartstack/services/#{organization}/#{namespace}/#{service.real_name}/instances"
          }
        end
      end
    end
  end
end
