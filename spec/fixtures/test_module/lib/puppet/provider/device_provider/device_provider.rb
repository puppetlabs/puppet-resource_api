require 'puppet/resource_api'

# A example/test provider for Device support
class Puppet::Provider::DeviceProvider::DeviceProvider
  def get(_context)
    [{ name: 'wibble', ensure: 'present', string: 'sample', string_ro: 'fixed' }]
  end

  def set(context, changes); end

  def canonicalize(_context, resources)
    if resources[0][:name] == 'wibble'
      resources[0][:string] = 'changed'
    end
    resources
  end
end
