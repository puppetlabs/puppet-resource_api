require 'puppet/resource_api/transport/wrapper'

module Puppet::Util::NetworkDevice::Test_device # rubocop:disable Style/ClassAndModuleCamelCase
  class Device < Puppet::ResourceApi::Transport::Wrapper
    def initialize(url_or_config, _options = {})
      puts url_or_config.inspect
      super('test_device', url_or_config)
    end
  end
end
