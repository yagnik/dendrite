module Dendrite
  module Validator
    def valid?
      super

      dependancies.each do |depname, dep|
        if dep.invalid?
          dep.errors.each do |key, value|
            errors.add "dependancy_#{key}", value
          end
        end
      end

      ports.each do |depname, dep|
        if dep.invalid?
          dep.errors.each do |key, value|
            errors.add "port_#{key}", value
          end
        end
      end

      if deploy && deploy.invalid?
        deploy.errors.each do |key, value|
          errors.add "deploy_#{key}", value
        end
      end

      if scale && scale.invalid?
        scale.errors.each do |key, value|
          errors.add "scale_#{key}", value
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
      validate :service_type

      def service_type
        unless service.is_a?(ServiceNode)
          errors.add(:service, "service has to be a Service Node")
        end
      end
    end

    Scale = Struct.new(:max_instance_count, :min_instance_count) do
      include ActiveModel::Validations
      validates_presence_of :max_instance_count
      validates_presence_of :min_instance_count
      validates :max_instance_count, numericality: { only_integer: true }
      validates :min_instance_count, numericality: { only_integer: true }
    end

    Deploy = Struct.new(:repository, :package) do
      include ActiveModel::Validations
      validates_presence_of :repository
      validates_presence_of :package
    end

    VALID_TYPE = %w(
      tomcat
      mysql
      mongodb
      aerospike
      cassandra
    )

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

    attr_reader :organization, :namespace, :lead_email, :team_email,
                :type, :deploy, :scale, :ports, :dependancies
                # :name is set but magically

    validates_presence_of :organization, :namespace, :lead_email, :team_email,
                          :name, :type, :deploy, :scale

    validates :organization, format: { with: /\A[a-z]+\z/, message: "only allows lowercase letters" }
    validates :namespace, format: { with: /\A[a-z]+\z/, message: "only allows lowercase letters" }
    validates :lead_email, format: { with: VALID_EMAIL_REGEX, message: "invalid email format" }
    validates :team_email, format: { with: VALID_EMAIL_REGEX, message: "invalid email format" }
    validates :name, format: { with: /\A[a-z_]+\z/, message: "only allows lowercase letters" }
    validates :type, inclusion: { in: VALID_TYPE, message: "%{value} is not a valid type" }

    def initialize(**args)
      @ports = {}
      args.each do |k,v|
        case k
        when :ports
          v.each do |name, port|
            @ports[name] = Port.new(name, port)
          end
        when :deploy
          @deploy = Deploy.new(v[:repository], v[:package]) if v != nil
        when :scale
          @scale = Scale.new(v[:max_instance_count], v[:min_instance_count]) if v != nil
        else
          instance_variable_set("@#{k}", v)
        end
      end
      @dependancies = {}
    end

    def real_name
      @name
    end

    def name
      "#{organization}_#{namespace}_#{@name}" if @name
    end

    def listening_port
      ports[:listening_port].port if ports[:listening_port]
    end

    def advertised_port
      ports[:advertised_port].port if ports[:advertised_port]
    end

    def add_dependancy(service:, latency:)
      @dependancies[service.name] = Dependacy.new(service, latency)
    end
  end
end
