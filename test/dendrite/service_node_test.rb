require 'test_helper'

module Dendrite
  class ServiceNodeTest < Minitest::Test
    extend Minitest::Spec::DSL

    let(:valid_service) do
     {
        namespace: 'namespace',
        lead_email: 'lead@email.com',
        team_email: 'team@email.com',
        name: "service",
        type: "tomcat",
        repo: "git@github.com",
        package_name: "service_package"
      }
    end

    def test_add_dependancy
      service1 = ServiceNode.new(valid_service)
      service2 = ServiceNode.new(valid_service.merge({name: "another_service"}))
      service1.add_dependancy(service: service2, latency: 1)
      assert_equal service1.dependancies.length, 1
      assert_equal service1.dependancies['another_service'].service, service2
    end

    def test_presence_validation
      %i(namespace lead_email team_email name type repo package_name).each do |key|
        service = ServiceNode.new(key => nil)
        refute service.valid?
        assert service.errors.messages[key], "#{key} should not be nil"
      end
    end

    def test_format_validation
      %i(namespace name).each do |key|
        service = ServiceNode.new(valid_service)
        assert service.valid?
        service = ServiceNode.new(valid_service.merge({key => '1'}))
        refute service.valid?
        assert service.errors.messages[key], "#{key} should not have numbers"
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

    def test_dependancy_validation
      dependancy = ServiceNode::Dependacy.new
      refute dependancy.valid?
      assert dependancy.errors.messages[:service], ":service should be present"
      assert dependancy.errors.messages[:latency], ":latency should be present"
    end
  end
end
