module Dendrite
  class ServiceGraph
    extend Forwardable

    attr_reader :services
    def_delegators :services, :each, :each

    def initialize
      @services = {}
    end

    def <<(service)
      raise KeyError unless service.name
      raise DuplicateService if services.keys.include?(service.name)
      services[service.name] = service
    end

    def [](name)
      services.fetch(name)
    end

    def valid?
      services.values.collect(&:valid?).all? &&
      services.values.group_by(&:advertised_port).all? do |port, svc|
        svc.length == 1
      end
    end

    def errors
      hash = services.inject({}) do |hash, (name, service)|
        hash[name] = service.errors.messages if service.errors.messages.length > 0
        hash
      end
      services.values.group_by(&:advertised_port).each do |port, svc|
        if svc.length > 1
          hash[:port_collisions] ||= {}
          hash[:port_collisions][port] = svc.collect(&:name)
        end
      end
      return hash
    end
  end
end
