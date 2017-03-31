module Dendrite
  module Generators
    class Nerve < Base
      # We use this for batch jobs so they can register
      DEFAULT_PORT = 1111

      def initialize(graph:, service_names:)
        super
        @services = @services.collect { |service| ServiceConfig.new(service)}
      end

      def to_h
        service_list = services.inject({}) do |hash, service|
          if service.read_write
            hash[service.name] = service.to_h
            hash["#{service.name}_readonly"] = service.to_h.merge({
              zk_path: "/smartstack/services/#{service.organization}/#{service.component}/#{service.service.real_name}_readonly/instances"
            })
          elsif service.read_only
            hash["#{service.name}_readonly"] = service.to_h.merge({
              zk_path: "/smartstack/services/#{service.organization}/#{service.component}/#{service.service.real_name}_readonly/instances"
            })
          else
            hash[service.name] = service.to_h
          end

          hash
        end

        {
          instance_id: Dendrite::Config.instance
        }.merge({services: service_list})
      end

      ServiceConfig = Struct.new(:service) do
        extend Forwardable
        def_delegator :service, :name, :name
        def_delegator :service, :component, :component
        def_delegator :service, :organization, :organization

        def read_only
          service.metadata && service.metadata.read_only
        end

        def read_write
          read_only && service.metadata.write_only
        end

        def to_h
          {
            host: Dendrite::Config.public_ip,
            port: service.service_port || DEFAULT_PORT,
            labels: {
              dc: Dendrite::Config.dc,
              env: Dendrite::Config.env
            }
          }.merge(zookeeper_config).merge(check_config)
        end

        def check_config
          return {} if not (service.service_port && service.telemetry && service.telemetry.health_url)
          {
            check_interval: Dendrite::Config.default_check_time,
            checks: [{
              type: "http"
              host: Dendrite::Config.public_ip,
              port: service.service_port,
              uri: service.telemetry.health_url,
              rise: 3,
              fall: 2
            }]
          }
        end

        def zookeeper_config
          {
            reporter_type: 'zookeeper',
            zk_hosts: Dendrite::Config.zk_hosts,
            zk_path: "/smartstack/services/#{organization}/#{component}/#{service.real_name}/instances"
          }
        end
      end
    end
  end
end
