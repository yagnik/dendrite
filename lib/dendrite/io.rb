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

      def write(data:, destination:)
        File.open(destination, 'w') do |file|
          file.write(data)
        end
      end

      def read(source:)
        YAML::load(File.open(source)).deep_symbolize_keys
      end

      def services_from_file(source:)
        data = read(source)
        data[:services].collect do |service|
          service[:namespace] = data[:namespace]
          service[:lead_email] = data[:lead_email]
          service[:team_email] = data[:team_email]
          service
        end
      end

      def services_from_folder(source:)
        Dir["#{source}/*.yml"].collect {|file| services_from_file(source: file)}
                              .flatten
      end
    end
  end
end
