require 'hocon'
require 'hocon/config_syntax'

# avoid loading puppet code base
module Puppet::Util; end
# avoid loading puppet code base
class Puppet::Util::NetworkDevice; end
module Puppet::Util::NetworkDevice::Simple
  # A basic device class, that reads its configuration from the provided URL.
  # The URL has to be a local file URL.
  class Device
    def initialize(url_or_config, _options = {})
      if url_or_config.is_a? String
        @url = URI.parse(url_or_config)
        raise "Unexpected url '#{url_or_config}' found. Only file:/// URLs for configuration supported at the moment." unless @url.scheme == 'file'
      else
        @config = url_or_config
      end
    end

    def facts
      {}
    end

    def return_custom_facts
      custom_fact_folder = Puppet[:pluginfactdest]
      files = Dir["#{custom_fact_folder}/*.rb"]
      files = [] unless files.is_a?(Array)
      Puppet.debug("Loading #{files.size} custom facts from #{custom_fact_folder}")
      files
    end

    def config
      raise "Trying to load config from '#{@url.path}, but file does not exist." if @url && !File.exist?(@url.path)
      @config ||= Hocon.load(@url.path, syntax: Hocon::ConfigSyntax::HOCON)
    end
  end

  # This class is implemented by custom facts, it allows users to add their own values to the fact hash.
  class CustomFact
    def add_fact(_context, _facts)
      raise 'Custom facts must implement this'
    end
  end
end
