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
      services.values.collect(&:valid?).all?
    end

    def errors
      services.inject({}) do |hash, (name, service)|
        hash[name] = service.errors.messages
        hash
      end
    end
  end
end
