module Dendrite
  class IO
    class << self
      def load(source:)
        graph = Dendrite::ServiceGraph.new
        services = IO.services_from_folder(source: source)

        services.each do |service|
          graph << ServiceNode.new(service)
        end

        services.each do |service|
          service[:dependancies].each do |deps|
            graph[service[:name]].add_dependancy(service: graph.fetch(deps[:name]), latency: deps[:latency])
          end
        end

        graph
      end

      def services_from_file(source:)
        data = YAML::load(File.open(source)).deep_symbolize_keys
        data[:services].collect do |service|
          service[:namespace] = data[:namespace]
          service[:lead_email] = data[:lead_email]
          service[:team_email] = data[:team_email]
          service
        end
      end

      def services_from_folder(source:)
        services = Dir["#{source}/*.yml"].collect do |file|
          services_from_file(source: file)
        end
        services.flatten
      end
    end
  end
end
