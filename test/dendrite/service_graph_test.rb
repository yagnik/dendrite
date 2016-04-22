require 'test_helper'

module Dendrite
  class ServiceGraphTest < Minitest::Test
    extend Minitest::Spec::DSL

    let(:valid_service) do
     {
        namespace: 'namespace',
        lead_email: 'lead@email.com',
        team_email: 'team@email.com',
        name: nil,
        type: "tomcat",
        repo: "git@github.com",
        package_name: "service_package"
      }
    end

    let(:service_foo) do
      ServiceNode.new(valid_service.merge({name: 'service_foo'}))
    end

    let(:service_bar) do
      ServiceNode.new(valid_service.merge({name: 'service_bar'}))
    end

    let(:service_graph) do
      ServiceGraph.new
    end

    def test_appends_service
      service_graph << service_foo
      assert_equal service_graph.services.length, 1
      assert_equal service_graph.services['service_foo'], service_foo
    end

    def test_lookup_returns_service_by_name
      service_graph << service_foo
      assert_equal service_graph['service_foo'], service_foo
    end

    def test_lookup_returns_nil_if_service_not_found
      assert_nil service_graph['service_foo']
    end

    def test_fetch_raises_if_service_not_found
      assert_raises(KeyError) do
        service_graph.fetch('service_foo')
      end
    end

    def test_valid_returns_true_if_no_error_in_graph
      service_graph << service_foo
      service_graph << service_bar
      service_foo.add_dependancy(service: service_bar, latency: 1)
      assert service_graph.valid?
    end

    def test_valid_returns_false_if_one_node_is_bad
      service_graph << ServiceNode.new(valid_service.merge({name: 'service_foo', lead_email: nil}))
      service_graph << service_bar
      refute service_graph.valid?
    end

    def test_errors_list_errors_for_each_node
      service_graph << ServiceNode.new(valid_service.merge({name: 'service_foo', lead_email: nil}))
      refute service_graph.valid?
      assert_equal service_graph.errors['service_foo'].length, 1
      assert_match service_graph.errors['service_foo'][:lead_email].first, "can't be blank"
    end
  end
end
