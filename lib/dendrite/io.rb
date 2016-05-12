require 'fileutils'

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
          node = ServiceNode.new(service)
          if service[:dependencies]
            service[:dependencies].each do |deps|
              dependency_name = "#{service[:organization]}_#{deps[:component]}_#{deps[:subcomponent]}"
              graph[node.name].add_dependency(service: graph[dependency_name], latency: deps[:latency])
            end
          end
        end

        graph
      end

      def write(data:, destination:)
        FileUtils::mkdir_p(File.dirname(destination))
        File.open(destination, 'w') do |file|
          file.write(data)
        end
      end

      def read(source:)
        YAML::load(File.open(source)).deep_symbolize_keys
      end

      def services_from_file(source:)
        data = read(source: source)
        data[:subcomponents].collect do |service|
          service[:organization] = data[:organization]
          service[:component]    = data[:component]
          service[:lead_email]   = data[:lead_email]
          service[:team_email]   = data[:team_email]
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
