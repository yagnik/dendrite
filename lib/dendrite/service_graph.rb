module Dendrite
  class ServiceGraph
    include ActiveModel::Validations
    extend Forwardable

    attr_reader :services
    def_delegators :services, :each, :each
    def_delegators :services, :keys, :keys
    def_delegators :services, :values, :values

    validate :validate_nodes
    validate :collisions

    def initialize
      @services = {}
    end

    def <<(service)
      raise KeyError unless service.name
      raise DuplicateService, service.name if services.keys.include?(service.name)
      services[service.name] = service
    end

    def [](name)
      services.fetch(name)
    end

    def collisions
      services.values.group_by(&:loadbalancer_port)
                     .reject {|port, svc| port == nil}
                     .select {|port, svc| svc.length > 1}
                     .each do |port, svc|
        errors.add("port_collisions_#{port}", "collision between #{svc.collect(&:name).join(',')}")
      end
    end

    def validate_nodes
      services.each do |name, service|
        errors.add(name, service.errors.messages) unless service.valid?
      end
    end
  end
end
