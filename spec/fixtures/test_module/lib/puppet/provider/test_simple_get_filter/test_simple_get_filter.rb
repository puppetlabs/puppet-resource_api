require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_simple_get_filter type using the Resource API.
class Puppet::Provider::TestSimpleGetFilter::TestSimpleGetFilter < Puppet::ResourceApi::SimpleProvider
  def get(_context, names = nil)
    if names.nil?
      [
        {
          name: 'bar',
          ensure: 'present',
          test_string: 'default',
        },
        {
          name: 'foo',
          ensure: 'present',
          test_string: 'default',
        },
      ]
    elsif names.include?('foo')
      [
        {
          name: 'foo',
          ensure: 'absent',
          test_string: 'foo found',
        },
      ]
    else
      [
        {
          name: 'foo',
          ensure: 'present',
          test_string: 'not foo',
        },
      ]
    end
  end

  def create(_context, _name, _should); end

  def update(_context, _name, _should); end

  def delete(_context, _name); end
end
