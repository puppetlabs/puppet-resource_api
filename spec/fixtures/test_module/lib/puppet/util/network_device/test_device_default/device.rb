require 'puppet/resource_api/transport/wrapper'

class Puppet::Util::NetworkDevice; end

module Puppet::Util::NetworkDevice::Test_device_default # rubocop:disable Style/ClassAndModuleCamelCase
  # The main class for handling the connection and command parsing to the IOS Catalyst device
  class Device < Puppet::ResourceApi::Transport::Wrapper
    def initialize(url_or_config, _options = {})
      super('test_device_default', url_or_config)
    end
  end
end