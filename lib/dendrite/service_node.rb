module Dendrite
  class ServiceNode
    include ActiveModel::Validations

    Port = Struct.new(:name, :port) do
      include ActiveModel::Validations
      validates! :name, presence: true
      validates! :port, presence: true
    end

    Dependacy = Struct.new(:service, :latency) do
      include ActiveModel::Validations
      validates! :service, presence: true
      validates! :latency, presence: true
    end


    attr_reader :namespace, :lead_email, :team_email,
                :name, :type, :repo, :package_name,
                :error_budget

    attr_accessor :ports, :dependancies

    validates_presence_of :namespace, :lead_email, :team_email,
                          :name, :type, :repo, :package_name

    def initialize(namespace:, lead_email:, team_email:, name:, type:, repo:)
      @namespace, @lead_email, @team_email = namespace, lead_email, team_email
      @dependancies = {}
      @ports = []
    end

    def to_s
      name
    end

    def add_dependancy(service:, latency:)
      @dependancies[service.name] = Dependacy.new(service: service, latency: latency)
    end
  end
end
