module Dendrite
  module Generators
    class Synapse < Base
      attr_reader :read_only
      def initialize(graph:, service_names:, environment: :dev)
        super(graph: graph, service_names: service_names)
        dep = []
        read_only = {}
        @services.each do |service|
          service.dependencies.each do |_, dependency|
            dep << dependency.service
            if read_only.keys.include?(dependency.service.name)
              if read_only[dependency.service.name] != dependency.read_only
                raise "Trying to add r/o and r/w for same service"
              end
            else
              read_only[dependency.service.name] = dependency.read_only
            end
          end
        end

        @read_only = read_only
        @services = dep.uniq
        @services.group_by { |service| service.loadbalancer_port }.each do |port, services|
          if services.length > 1
            raise PortCollision, "Port collission between #{services.collect(&:name).join(',')}"
          end
        end
        @services = @services.collect { |service| ServiceConfig.new(service, environment)}
      end

      def to_h
        service_list = services.inject({}) do |hash, service|

          if read_only[service.name]
            data = service.to_h
            discovery_data = data[:discovery].merge({
              path: "/smartstack/services/#{service.organization}/#{service.component}/#{service.service.real_name}_readonly/instances"
            })
            data[:discovery] = discovery_data
            hash[service.name] = data
          else
            hash[service.name] = service.to_h
          end
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
        def_delegator :service, :domain_names, :domain_names
        def_delegator :service, :metadata, :metadata


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
          data = {
            haproxy: {
              port: service.loadbalancer_port,
              bind_address: bind_address,
              server_options: Dendrite::Config.server_options,
              listen: mode,
              cookie_value_method: 'hash',
              backend_order: (metadata && metadata.sticky_session) || Dendrite::Config.sticky ? 'asc' : nil
            }
          }

          if domain_names[environment] && domain_names[environment].length > 0
            data[:haproxy][:shared_frontend] = [
              "acl is_#{name} hdr_dom(host) " + domain_names[environment].collect {|dns| " -i #{dns.domain_name} "}.join ,
              "use_backend #{name} if is_#{name}"
            ]
          end
          return data
        end

        def mode
          if Dendrite::Config.http_types.include?(service.type)
            arr = ['mode http', 'option httplog']
            key = metadata && metadata.sticky_session ? metadata.sticky_session : Dendrite::Config.cookie
            peer = Dendrite::Config.peer ? " peers #{Dendrite::Config.peer}": ''

            if Dendrite::Config.sticky
              if !(metadata && metadata.sticky_session)
                arr << "cookie #{key} insert nocache"
              end
            end

            if Dendrite::Config.sticky && metadata && metadata.sticky_session
              arr << "stick-table type string len 200 size 500m expire 30m#{peer}"
              arr << "stick store-response res.cook(#{key})"
              arr << "stick match req.cook(#{key})"
            end
            arr
          else
            ['mode tcp', 'option tcplog']
          end
        end

        def bind_address
          Dendrite::Config.bind_to_all? ? '0.0.0.0' : '127.0.0.1'
        end
      end
    end
  end
end
