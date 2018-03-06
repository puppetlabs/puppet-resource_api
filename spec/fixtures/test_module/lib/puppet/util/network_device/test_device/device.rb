require 'puppet/util/network_device/simple/device'

module Puppet::Util::NetworkDevice::Test_device
  class Device < Puppet::Util::NetworkDevice::Simple::Device
    def facts 
      { "foo" => "bar" }
    end
  end
end