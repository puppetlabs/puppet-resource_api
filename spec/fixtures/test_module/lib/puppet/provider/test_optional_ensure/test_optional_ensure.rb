require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_optional_ensure type using the Resource API.
class Puppet::Provider::TestOptionalEnsure::TestOptionalEnsure < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        namevar: 'existing',
        ensure: 'present',
        prop: 'my property',
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
