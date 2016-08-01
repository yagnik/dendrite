require 'test_helper'

module Dendrite
  class ServiceNodeTest < Minitest::Test
    extend Minitest::Spec::DSL

    let(:valid_service) do
     {
        organization: 'sd',
        component: 'component',
        lead_email: 'lead@email.com',
        team_email: 'team@email.com',
        name: 'foo',
        type: "tomcat",
        deploy: {
          repository: 'git@github.com:yagnik/dendrite',
          package: 'dendrite'
        },
        scale: {
          min_instance_count: 1,
          max_instance_count: 5
        },
        ports: {
          loadbalancer_port: 8081,
          service_port: 8080
        }
      }
    end

    def test_add_dependency
      service1 = ServiceNode.new(valid_service)
      service2 = ServiceNode.new(valid_service.merge({name: "another_service"}))
      service1.add_dependency(service: service2, latency: 1, identifier: nil)
      assert_equal service1.dependencies.length, 1
      assert_equal service1.dependencies[service2.name].service, service2
    end

    def test_presence_validation
      %i(component lead_email team_email name type).each do |key|
        service = ServiceNode.new(key => nil)
        refute service.valid?
        assert service.errors.messages[key], "#{key} should not be nil"
      end
    end

    def test_type_validation
      service = ServiceNode.new(valid_service)
      assert service.valid?
      service = ServiceNode.new(valid_service.merge({type: '1'}))
      refute service.valid?
      assert service.errors.messages[:type], ":type should be valid"
    end

    def test_port_validation
      port = ServiceNode::Port.new(nil, 1)
      refute port.valid?
      assert port.errors.messages[:name], ":name should be present"
      assert_nil port.errors.messages[:port]

      port = ServiceNode::Port.new
      refute port.valid?
      assert port.errors.messages[:name], ":name should be present"
      assert port.errors.messages[:port], ":port should be present"
    end

    def test_dependency_validation
      dependency = ServiceNode::Dependency.new
      refute dependency.valid?
      assert dependency.errors.messages[:service], ":service should be present"
      assert dependency.errors.messages[:latency], ":latency should be present"
    end
  end
end
