require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_bool type using the Resource API.
class Puppet::Provider::TestBool::TestBool < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'foo',
        ensure: 'present',
        test_bool: true,
        test_bool_param: true,
        variant_bool: true,
        optional_bool: true,
      },
      {
        name: 'bar',
        ensure: 'present',
        test_bool: false,
        test_bool_param: false,
        variant_bool: false,
        optional_bool: false,
      },
      {
        name: 'wibble',
        ensure: 'present',
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
