require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_array type using the Resource API.
class Puppet::Provider::TestArray::TestArray < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'foo',
        ensure: 'present',
        some_array: %w[a b c],
      },
      {
        name: 'bar',
        ensure: 'present',
        some_array: [],
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
