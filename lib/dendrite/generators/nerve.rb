module Dendrite
  module Generators
    class Nerve < Base
      def to_h
        service_list = services.inject({}) do |hash, service|
          hash[service.name] = service.to_h
          hash
        end

        {
          instance_id: Dendrite::Config.instance
        }.merge({services: service_list})
      end

      private
      ServiceConfig = Struct.new(:service) do
        delegate :name, :namespace, service

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
            zk_path: "/smartstack/services/#{service.namespace}/#{service.name}/instances"
          }
        end
      end
    end
  end
end
