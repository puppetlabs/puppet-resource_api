require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_simple_get_filter type using the Resource API.
class Puppet::Provider::TestSimpleGetFilter::TestSimpleGetFilter < Puppet::ResourceApi::SimpleProvider
  def get(_context, names = nil)
    result = if names.nil?
               # rather than fething everything from your large dataset, return a subset of the data that you are happy to show.
               # This will be cached by Puppet. If a resource requested exists in the cache, then no futher calls are made to the provider.
               [{
                 name: 'wibble',
                 ensure: 'present',
                 test_string: 'wibble default',
               },
                {
                  name: 'bar',
                  ensure: 'present',
                  test_string: 'bar default',
                }]
             else
               # If the resource(s) requested does not exist in the cache the provider will be called with its name(s)
               # and a subsequent query to your large dataset can be made with that information
               names.map { |name| { name: name, ensure: 'present', test_string: "#{name} found" } }
             end
    result
  end

  def create(_context, _name, _should); end

  def update(_context, _name, _should); end

  def delete(_context, _name); end
end
