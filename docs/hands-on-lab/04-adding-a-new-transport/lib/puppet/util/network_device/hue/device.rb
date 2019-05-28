require 'puppet/resource_api/transport/wrapper'

# Initialize the NetworkDevice module if necessary
class Puppet::Util::NetworkDevice; end

# The Hue module only contains the Device class to bridge from puppet's internals to the Transport.
# All the heavy lifting is done bye the Puppet::ResourceApi::Transport::Wrapper
module Puppet::Util::NetworkDevice::Hue
  # Bridging from puppet to the hue transport
  class Device < Puppet::ResourceApi::Transport::Wrapper
    def initialize(url_or_config, _options = {})
      super('hue', url_or_config)
    end
  end
end
