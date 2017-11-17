require 'hocon'
require 'hocon/config_syntax'
require 'puppet/util/network_device/base'

module Puppet::Util::NetworkDevice::Simple
  # A basic device class, that reads its configuration from the provided URL.
  # The URL has to be a local file URL.
  class Device
    def initialize(url, _options = {})
      @url = URI.parse(url)
      raise "Unexpected url '#{url}' found. Only file:/// URLs for configuration supported at the moment." unless @url.scheme == 'file'
    end

    def facts
      {}
    end

    def config
      raise "Trying to load config from '#{@url.path}, but file does not exist." unless File.exist? @url.path
      @config ||= Hocon.load(@url.path, syntax: Hocon::ConfigSyntax::HOCON)
    end
  end
end
