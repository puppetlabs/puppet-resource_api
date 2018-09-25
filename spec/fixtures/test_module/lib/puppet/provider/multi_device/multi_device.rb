require 'puppet/resource_api/simple_provider'

# Implementation for the multi_device type using the Resource API.
# default provider class
class Puppet::Provider::MultiDevice::MultiDevice < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    []
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end
end
