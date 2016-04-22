module Dendrite
  class ServiceGraph
    attr_reader :services

    def initialize
      @services = {}
    end

    def <<(service)
      raise KeyError unless service.name
      @services[service.name] = service
    end

    def [](name)
      @services[name]
    end

    def fetch(name)
      @services.fetch(name)
    end

    def valid?
      @services.values.collect(&:valid?).all?
    end

    def errors
      @services.inject({}) do |hash, (name, service)|
        hash[name] = service.errors.messages
        hash
      end
    end
  end
end
