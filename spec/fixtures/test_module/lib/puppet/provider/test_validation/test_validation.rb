require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_validation type using the Resource API.
class Puppet::Provider::TestValidation::TestValidation < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'foo',
        ensure: :present,
        prop: 2,
        prop_ro: 8,
      },
      {
        name: 'bar',
        ensure: :present,
        prop: 3,
        prop_ro: 9,
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
