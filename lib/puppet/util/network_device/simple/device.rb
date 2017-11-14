require 'puppet/util/network_device/base'

module Puppet::Util::NetworkDevice::Simple
  # an example/test device
  class Device
    attr_accessor :url, :debug

    def initialize(url, options = {})
      @url = URI.parse(url)
      @debug = options[:debug]
    end

    def facts
      {}
    end
  end
end
