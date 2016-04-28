module Dendrite
  module Validator
    def valid?
      super

      @dependancies.each do |depname, dep|
        if dep.invalid?
          dep.errors.each do |key, value|
            errors.add "dependancy_#{key}", value
          end
        end
      end

      @ports.each do |dep|
        if dep.invalid?
          dep.errors.each do |key, value|
            errors.add "port_#{key}", value
          end
        end
      end

      return errors.count == 0
    end
  end

  class ServiceNode
    include ActiveModel::Validations
    prepend Validator

    Port = Struct.new(:name, :port) do
      include ActiveModel::Validations
      validates_presence_of :name
      validates_presence_of :port
      validates :port, numericality: { only_integer: true }
    end

    Dependacy = Struct.new(:service, :latency) do
      include ActiveModel::Validations
      validates_presence_of :service
      validates_presence_of :latency
    end

    VALID_TYPE = %w(
      tomcat
      mysql
      mongodb
      aerospike
      cassandra
    )

    attr_reader :namespace, :lead_email, :team_email,
                :name, :type, :repo, :package_name,
                :ports, :dependancies

    validates_presence_of :namespace, :lead_email, :team_email,
                          :name, :type, :repo, :package_name

    validates :namespace, format: { with: /\A[a-z_]+\z/, message: "only allows lowercase letters" }
    validates :name, format: { with: /\A[a-z_]+\z/, message: "only allows lowercase letters" }
    validates :type, inclusion: { in: VALID_TYPE, message: "%{value} is not a valid type" }

    def initialize(**args)
      @ports = {}
      args.each do |k,v|
        if k == :ports
          ports.each do |name, port|
            @ports[name] << Port.new(name, port)
          end
        else
          instance_variable_set("@#{k}", v)
        end
      end
      @dependancies = {}
    end

    def listening_port
      ports[:lb_port].port
    end

    def advertised_port
      ports[:advertised_port].port
    end

    def add_dependancy(service:, latency:)
      @dependancies[service.name] = Dependacy.new(service, latency)
    end
  end
end
