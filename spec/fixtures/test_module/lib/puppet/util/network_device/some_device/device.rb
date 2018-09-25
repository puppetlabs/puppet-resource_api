require 'puppet/util/network_device/simple/device'

module Puppet::Util::NetworkDevice::Some_device # rubocop:disable Style/ClassAndModuleCamelCase
  # A simple test device returning hardcoded facts
  class Device < Puppet::Util::NetworkDevice::Simple::Device
    def facts
      { 'foo' => 'bar' }
    end
  end
end
