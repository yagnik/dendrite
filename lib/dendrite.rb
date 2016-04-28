require 'yaml'
require 'json'
require 'active_model'
require "dendrite/version"
require 'dendrite/io'
require "dendrite/service_node"
require "dendrite/service_graph"
require "dendrite/generators/base"
require "dendrite/generators/nerve"
require "dendrite/generators/synapse"

module Dendrite
  InvalidData = StandardError
  UnknownService = StandardError

  class Config
    @@data = Dendrite::IO.read(source)

    class << self
      def dc
        @@data.fetch(:dc)
      end

      def env
        @@data[:env] || :dev
      end

      def zk_hosts
        @@data[:zk_hosts]
      end

      def nerve_config_path
        @@data[:nerve_config]
      end

      def synapse_config_path
        @@data[:synapse_config]
      end

      def global_haproxy_config
        @@data[:haproxy_config]
      end

      def public_ip

      end

      def fqdn
      end

      def instance
        fqdn.gsub('.', '_')
      end
    end
  end
end


