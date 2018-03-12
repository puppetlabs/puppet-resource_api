require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_autorequire type using the Resource API.
class Puppet::Provider::TestAutorequire::TestAutorequire < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'foo',
        ensure: :present,
      },
      {
        name: 'bar',
        ensure: :present,
      },
    ]
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
