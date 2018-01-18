require 'puppet/resource_api'

# A example/test provider for Device support
class Puppet::Provider::DeviceProvider::DeviceProvider
  def get(_context)
    []
  end

  def set(context, changes); end
end
