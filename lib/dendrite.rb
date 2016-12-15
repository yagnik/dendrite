require 'yaml'
require 'json'
require 'active_model'
require 'socket'
require 'forwardable'
require 'ostruct'
require 'dendrite/version'

module Dendrite
  Error = Class.new(StandardError)
  InvalidData = Class.new(Error)
  UnknownService = Class.new(Error)
  DuplicateService = Class.new(Error)
  PortCollision = Class.new(Error)

  class Config
    class << self
      def load(source:)
        @@data = Dendrite::IO.read(source: source)
      end

      def services_source
        @@data[:dendrite].fetch(:services_source)
      end

      def dc
        @@data[:dendrite].fetch(:dc)
      end

      def env
        @@data[:dendrite][:env] || :dev
      end

      def zk_hosts
        @@data[:dendrite][:zk_hosts]
      end

      def nerve_config_path
        @@data[:dendrite][:nerve_config_path]
      end

      def synapse_config_path
        @@data[:dendrite][:synapse_config_path]
      end

      def global_haproxy_config
        @@data[:synapse][:haproxy]
      end

      def server_options
        @@data[:synapse][:server_options]
      end

      def peer
        if @@data[:synapse][:haproxy][:extra_sections]
          key = @@data[:synapse][:haproxy][:extra_sections].keys.collect(&:to_s).find {|k| k.include?("peers")}
          key ? key.split("peers").last.strip : nil
        end
      end

      def custom_frontend!(name:, port:, backend_name:)
        data = {
          "frontend #{name}": [
            "bind :#{port}",
            "use_backend #{backend_name}"
          ]
        }
        @@data[:synapse][:haproxy][:extra_sections] = @@data[:synapse][:haproxy][:extra_sections].merge(data)
      end

      def valid_types
        @@data[:dendrite][:valid_app_types]
      end

      def http_types
        @@data[:dendrite][:http_app_types] || []
      end

      def cookie
        @@data[:dendrite][:cookie] || "COOKME"
      end

      def sticky
        @@data[:dendrite][:sticky]
      end

      def bind_to_all?
        @@data[:dendrite][:bind_to_all] != nil
      end

      def public_ip
        ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?} ||
             Socket.ip_address_list.detect{|intf| intf.ipv4? && !intf.ipv4_loopback? && !intf.ipv4_multicast? && !intf.ipv4_private?}
        ip.ip_address if ip
      end

      def fqdn
        Socket.gethostbyname(Socket.gethostname).first
      end

      def instance
        fqdn
      end
    end
  end
end

require 'dendrite/io'
require 'dendrite/service_node'
require 'dendrite/service_graph'
require 'dendrite/generators/base'
require 'dendrite/generators/nerve'
require 'dendrite/generators/synapse'
