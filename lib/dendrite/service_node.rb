module Dendrite
  module Validator
    def valid?
      super

      dependencies.each do |depname, dep|
        if dep.invalid?
          dep.errors.each do |key, value|
            errors.add "dependency_#{key}", value
          end
        end
      end

      ports.each do |name, prt|
        if prt.invalid?
          prt.errors.each do |key, value|
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

      if telemetry && telemetry.invalid?
        telemetry.errors.each do |key, value|
          errors.add "telemetry_#{key}", value
        end
      end

      return errors.count == 0
    end
  end

  class ServiceNode
    include ActiveModel::Validations
    prepend Validator

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

    Telemetry = Struct.new(:health_url, :notification_email) do
      include ActiveModel::Validations
      validates_presence_of :health_url
      validates_presence_of :notification_email
      validates :notification_email, format: { with: ServiceNode::VALID_EMAIL_REGEX, message: "invalid email format" }
    end

    Port = Struct.new(:name, :port) do
      include ActiveModel::Validations
      validates_presence_of :name
      validates_presence_of :port
      validates :port, numericality: { only_integer: true }
    end

    Dependency = Struct.new(:service, :latency) do
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

    attr_reader :organization, :component, :lead_email, :team_email,
                :type, :deploy, :scale, :ports, :dependencies, :telemetry
                # :name is set but magically

    validates_presence_of :organization, :component, :lead_email, :team_email,
                          :name, :type

    validates :organization, format: { with: /\A[a-z]+\z/, message: "only allows lowercase letters" }
    validates :component, format: { with: /\A[0-9a-z]+\z/, message: "only allows lowercase letters" }
    validates :lead_email, format: { with: VALID_EMAIL_REGEX, message: "invalid email format" }
    validates :team_email, format: { with: VALID_EMAIL_REGEX, message: "invalid email format" }
    validates :name, format: { with: /\A[0-9a-z]+\z/, message: "only allows lowercase letters" }
    validates :type, inclusion: { in: -> (_) { Dendrite::Config.valid_types } , message: "%{value} is not a valid type" }

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
        when :telemetry
          @telemetry = Telemetry.new(v[:health_url], v[:notification_email]) if v != nil
        else
          instance_variable_set("@#{k}", v)
        end
      end
      @dependencies = {}
    end

    def real_name
      @name
    end

    def name
      "#{organization}_#{component}_#{@name}" if @name
    end

    def service_port
      ports[:service_port].port if ports[:service_port]
    end

    def loadbalancer_port
      ports[:loadbalancer_port].port if ports[:loadbalancer_port]
    end

    def add_dependency(service:, latency:)
      @dependencies[service.name] = Dependency.new(service, latency)
    end

    def to_h
      data = {
        organization: organization,
        component: component,
        name: real_name,
        complete_name: name,
        lead_email: lead_email,
        team_email: team_email,
        type: type,
        ports: ports.values.collect(&:to_h),
        dependencies: dependencies.keys
      }
      data.merge!({deploy: deploy.to_h}) if deploy
      data.merge!({scale: scale.to_h}) if scale
      data.merge!({telemetry: telemetry.to_h}) if telemetry
      data
    end
  end
end
