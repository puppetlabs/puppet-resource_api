require 'puppet/resource_api'

# A example/test provider for Device support
class Puppet::Provider::DeviceProvider::DeviceProvider
  # TODO: remove when PDK-666 is solved
  def canonicalize(_context, resources)
    resources
  end

  def get(_context)
    puts Puppet::Util::NetworkDevice.current.inspect
    []
  end

  def set(context, changes); end
end
