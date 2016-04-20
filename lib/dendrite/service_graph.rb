module Dendrite
  class ServiceGraph
    attr_reader :services

    def self.load(source:)
      graph = self.new
      services = IO.services_from_folder(source)

      services.each do |service|
        graph << ServiceNode.new(*service)
      end

      services.each do |service|
        service[:dependancies].each do |deps|
          graph[service[:name]].add_dependancy(graph[deps[:name]], deps[:latency])
        end
      end

      graph
    end

    def initialize
      @services = {}
    end

    def <<(service)
      @services[service.name] = service
    end

    def [](name:)
      @services[name]
    end
  end
end
