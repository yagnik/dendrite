require 'test_helper'
require 'pry'

module Dendrite
  class ServiceGraphTest < Minitest::Test
    extend Minitest::Spec::DSL

    let(:valid_service) do
     {
        organization: 'sd',
        component: 'component',
        lead_email: 'lead@email.com',
        team_email: 'team@email.com',
        name: nil,
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
        },
        default_servers: [
          {
            host: "192.168.1.1",
            port: 80,
            environment: "stg"
          }
        ]
      }
    end

    let(:service_foo) do
      ServiceNode.new(valid_service.merge({name: 'servicefoo'}))
    end

    let(:service_bar) do
      ServiceNode.new(valid_service.merge({name: 'servicebar'}))
    end

    let(:service_graph) do
      ServiceGraph.new
    end

    def test_appends_service
      service_graph << service_foo
      assert_equal service_graph.services.length, 1
      assert_equal service_graph.services[service_foo.name], service_foo
    end

    def test_lookup_returns_service_by_name
      service_graph << service_foo
      assert_equal service_graph[service_foo.name], service_foo
    end

    def test_lookup_returns_nil_if_service_not_found
      assert_raises(KeyError) do
        service_graph['service_foo']
      end
    end

    def test_valid_returns_true_if_no_error_in_graph
      service_graph << service_foo
      service_graph << ServiceNode.new(valid_service.merge({name: 'servicebar', ports: {loadbalancer_port: 8082}}))
      service_foo.add_dependency(service: service_bar, latency: 1, identifier: nil)
      assert service_graph.valid?
    end

    def test_valid_returns_false_if_one_node_is_bad
      service_graph << ServiceNode.new(valid_service.merge({name: 'service_foo', lead_email: nil}))
      service_graph << service_bar
      refute service_graph.valid?
    end

    def test_errors_list_errors_for_each_node
      node = ServiceNode.new(valid_service.merge({name: 'service_foo', lead_email: nil}))
      service_graph << node
      refute service_graph.valid?
      assert_equal service_graph.errors.messages[node.name.to_sym].length, 1
      assert_match service_graph.errors.messages[node.name.to_sym].first[:lead_email].first, "can't be blank"
    end
  end
end
